# Laboratorio Terraform y AWS

Proyecto educativo para crear una red, una máquina Ubuntu con Nginx, un bucket S3 y PostgreSQL administrado en una cuenta AWS de pruebas. **No es una arquitectura de producción.** Los recursos generan cargos desde que se crean, incluso sin tráfico.

## Arquitectura

```text
Internet -- Internet Gateway -- subred pública (AZ 1) -- EC2 Ubuntu/Nginx :80
                                     |
                           SSH :22 solo desde tu IP
VPC -- subred privada (AZ 1) ---- RDS PostgreSQL :5432
    \- subred privada (AZ 2) ---- grupo de subredes de RDS
EC2 -- acceso privado a PostgreSQL por security group
S3 -- bucket privado con cifrado y versionado (servicio regional)
```

La segunda subred privada es necesaria porque un grupo de subredes RDS debe abarcar al menos dos zonas de disponibilidad. No implica que la base sea Multi-AZ: esta instancia es **Single-AZ**. Las subredes privadas no tienen ruta a Internet ni NAT; la pública tiene ruta al Internet Gateway. La EC2 recibe una IP pública para descargar Nginx. HTTP es público; SSH solo se admite desde el CIDR configurado. No se crean claves SSH ni usuarios de AWS.

| Módulo | Responsabilidad |
| --- | --- |
| `network` | VPC, Internet Gateway, una subred pública, dos privadas, tablas de rutas y security groups. |
| `compute` | Busca la AMI oficial Ubuntu 24.04 de Canonical y crea EC2 con Nginx mediante `user_data`. |
| `storage` | Bucket privado, bloqueo de acceso público, cifrado SSE-S3 y versionado. |
| `database` | Grupo de subredes y RDS PostgreSQL privado, cifrado y accesible solo desde la EC2. |

El directorio raíz es la única configuración Terraform. Los archivos de `environments/` son **ejemplos de valores**, no configuraciones independientes ni estados separados. Usar ambos con el mismo estado modifica la misma infraestructura; ver «Entornos» antes de aplicar.

## Requisitos

- Terraform 1.5 o superior, AWS CLI y credenciales con permisos para VPC, EC2, S3 y RDS.
- Una cuenta de pruebas, una región con al menos dos zonas de disponibilidad y cuotas suficientes. Por defecto se usa `us-east-1`.
- Una key pair EC2 existente en esa región si se desea acceder por SSH. Se puede omitir si solo se quiere usar HTTP.
- Tu IP pública en formato CIDR, por ejemplo `198.51.100.10/32`. No uses ese valor de ejemplo: reemplázalo por tu IP real.
- Acceso de red saliente para descargar proveedores y, desde EC2, paquetes Ubuntu.

Configura credenciales con un perfil o el mecanismo habitual de AWS; no las escribas en archivos del proyecto. Comprueba la cuenta activa:

```bash
aws configure --profile laboratorio
export AWS_PROFILE=laboratorio
aws sts get-caller-identity
```

## Primer despliegue

Trabaja desde la raíz del repositorio. Copia el ejemplo y edítalo:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Define `ssh_cidr` con tu IP y, si vas a usar SSH, `key_name` con el nombre de una key pair existente. Revisa región y costos antes de continuar. `terraform.tfvars` se carga automáticamente; los archivos `*.tfvars` reales están ignorados por Git.

La contraseña **no debe guardarse en el repositorio ni en `terraform.tfvars`**. Terraform la recibirá de esta variable de entorno; usa una contraseña propia de 8 a 128 caracteres ASCII imprimibles, sin espacios ni `"`, `/` o `@`:

```bash
read -rs -p "Contraseña de PostgreSQL: " TF_VAR_db_password; echo
export TF_VAR_db_password
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

`init` instala el proveedor; `plan` muestra los cambios; `apply` ejecuta exactamente el plan guardado. **El estado y los planes contienen la contraseña en texto claro**, aunque la variable sea `sensitive`: no los subas, compartas ni guardes en almacenamiento inseguro. `sensitive` oculta valores en la salida normal, no los cifra. El backend local es deliberado para aprender; para trabajo compartido usa estado remoto cifrado, acceso restringido y bloqueo.

El despliegue de RDS puede tardar varios minutos y la instalación de Nginx continúa después de que EC2 arranca:

```bash
terraform output
curl "$(terraform output -raw web_url)"
```

Para SSH, usa la clave privada correspondiente a `key_name`: `ssh -i /ruta/a/clave.pem ubuntu@IP_PUBLICA`, usando `ec2_public_ip` del output. Revisa `/var/log/cloud-init-output.log` si Nginx no está listo. La base no tiene IP pública: conéctate desde la EC2 a `db_endpoint`, por ejemplo instalando un cliente PostgreSQL allí. No se instala ningún cliente de base automáticamente.

## Entornos

`environments/dev/terraform.tfvars.example` y `environments/prod/terraform.tfvars.example` muestran diferencias de tamaño y nombre. **Prod es solo un ejercicio**, no cumple requisitos de alta disponibilidad, respaldo ni protección de producción. Copia uno a un archivo local ignorado y ajusta `ssh_cidr`, región y `key_name`:

```bash
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

Terraform también carga automáticamente cualquier `terraform.tfvars` de la raíz; el archivo `-var-file` prevalece para las variables que contiene. No apliques el ejemplo prod sobre el estado de dev esperando aislamiento. Usa directorios de trabajo separados con estados y credenciales adecuados, o configura un backend remoto y una estrategia explícita de aislamiento por entorno. Cada estado necesita su propio `init`, plan y destroy. Para destruir, usa el mismo directorio/estado y archivo de variables usados al aplicar.

## Conceptos y decisiones

- `versions.tf` declara el proveedor AWS y la versión mínima de Terraform. `terraform init` genera `.terraform.lock.hcl`, que conviene conservar en Git para reproducibilidad.
- El provider configura `default_tags`; los recursos etiquetables agregan `Name`. Asociaciones, reglas y configuraciones auxiliares que AWS no permite etiquetar heredan la identidad del recurso asociado.
- `variables.tf` define tipos, descripciones y validaciones; los valores concretos van en `terraform.tfvars` o en `TF_VAR_...`. Nunca agregues secretos a Git.
- `locals` centraliza el prefijo y las etiquetas. Los data sources consultan la cuenta, zonas disponibles y AMI oficial; por eso un plan requiere credenciales AWS.
- Los módulos reciben entradas y exponen salidas. Las referencias entre módulos crean dependencias implícitas; no hace falta usar `depends_on` para esos enlaces. La dependencia explícita de la instancia respecto de la asociación de ruta evita que arranque antes de tener conectividad para instalar paquetes.
- El grupo de seguridad de RDS permite PostgreSQL solo desde el grupo de EC2. IMDSv2 es obligatorio y el disco raíz y RDS están cifrados. No hay HTTPS, NAT, alta disponibilidad ni gestión profesional de secretos.
- La AMI más reciente puede cambiar entre planes y provocar el reemplazo de EC2. El script instala paquetes desde repositorios Ubuntu en el primer arranque; necesita Internet y puede fallar si estos no están disponibles.
- RDS se crea sin backups automáticos ni snapshot final para facilitar la limpieza. Esto **elimina los datos** al destruir y no es adecuado para producción. El bucket no se vacía automáticamente para evitar borrar datos por accidente.
- `outputs.tf` muestra valores útiles. El endpoint de RDS incluye host y puerto; las contraseñas no son outputs.

## Costos y limpieza

Los precios cambian por región y fecha. Como orientación **no vinculante**, en `us-east-1` una EC2 `t3.micro` Linux puede rondar USD 7,5/mes y una RDS PostgreSQL `db.t3.micro` USD 12–16/mes funcionando 730 horas; suma almacenamiento RDS (20 GB), almacenamiento y solicitudes S3, IPv4 pública, transferencia y posibles impuestos. El total puede superar USD 25/mes. Consulta [AWS Pricing Calculator](https://calculator.aws/) y las páginas de precios actuales antes de aplicar. El nivel gratuito depende de la cuenta y sus condiciones; no lo supongas. Configura alertas de AWS Budgets.

Para evitar cargos, termina el laboratorio cuanto antes:

1. Si agregaste objetos al bucket, elimina **todas las versiones y delete markers**, por ejemplo desde la consola S3; `aws s3 rm --recursive` por sí solo no vacía un bucket versionado. No borres datos que necesites.
2. Desde el mismo estado y con las mismas variables del despliegue:

   ```bash
   terraform plan -destroy
   terraform destroy
   unset TF_VAR_db_password
   ```

   Si usaste un archivo de entorno, añade `-var-file=environments/dev/terraform.tfvars` a ambos comandos. La contraseña debe seguir disponible hasta terminar el destroy.
3. Comprueba en la consola AWS que EC2, RDS, EBS, IPv4 pública, snapshots y S3 ya no generan cargos. Los recursos creados manualmente o fuera de este estado no se eliminan automáticamente. Conserva el estado de forma segura hasta verificar la limpieza.

## Ejercicios sugeridos

1. Añadir un Application Load Balancer y limitar el acceso HTTP directo a EC2.
2. Crear una segunda EC2 en otra zona pública y distribuir tráfico.
3. Configurar un Auto Scaling Group con una plantilla de lanzamiento.
4. Crear una tabla DynamoDB y exponer su nombre como output.
5. Configurar un backend remoto en S3 con cifrado, bloqueo compatible con la versión elegida y permisos mínimos.
6. Gestionar múltiples entornos con estados aislados y comparar sus planes.
7. Integrar GitHub Actions con OIDC, permisos mínimos y revisión de planes sin exponer secretos.
