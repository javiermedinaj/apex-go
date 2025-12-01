# ForgeAI Integration - Salesforce + Go Middleware

## Descripción del Proyecto

Demostración que integra **Salesforce** con una aplicación web moderna usando **Go** como intermediario. La arquitectura permite capturar leads desde un landing page desarrollado en **Astro** y enviarlos automáticamente a Salesforce a través de una API REST personalizada en **Apex**.

## Arquitectura

```
Frontend (Astro) → Middleware (Go) → Salesforce (Apex REST API)
                        ↓
                  Legacy DB (JSON)
```

### Componentes:

1. **Frontend**: Landing page de recruiting/HR desarrollado con Astro + Tailwind CSS
2. **Middleware**: Servidor HTTP en Go que orquesta la comunicación con Salesforce
   - Filtra leads consultando `legacy_db.json` por dominio de email
   - Clasifica clientes en tiers: **VIP**, **STANDARD**, o **BLACKLIST**
   - Enriquece el payload antes de enviarlo a Salesforce
3. **Backend**: Salesforce Apex REST API que maneja la creación de leads
4. **Infrastructure**: Terraform para desplegar en AWS EC2 (Ubuntu 22.04)

### Flujo de Datos:

1. Usuario completa formulario en frontend (Astro)
2. Go middleware recibe el lead y extrae el dominio del email
3. Consulta `legacy_db.json` para determinar el tier del cliente
4. Envía a Salesforce con metadata enriquecida (tier, source)
5. Apex API crea el Lead con Rating basado en tier:
   - **VIP** → `Rating: Hot` + descripción especial
   - **BLACKLIST** → `Status: Closed - Not Converted` + alerta
   - **STANDARD** → `Rating: Warm`

## Capturas de Pantalla
![PanelSalesForce](./demo/salesforce.png)

### Homepage Completa
![Homepage](./demo/homepage-full.png)

## Tecnologías Utilizadas

- **Frontend**: Astro 5.16.3, Tailwind CSS v4.1.17, React Icons
- **Middleware**: Go 1.21, godotenv
- **Backend**: Salesforce Apex REST API
- **Infrastructure**: Terraform, AWS EC2, Nginx
- **Deployment**: Ubuntu 22.04, Node.js 20, Go

## Estructura del Proyecto

```
forgeAI-integration/
├── frontend/          # Aplicación Astro
├── middleware/        # Servidor Go
├── salesforce/        # Apex REST API
├── infrastructure/    # Terraform AWS
└── demo/             # Capturas de pantalla
```

### Frontend
```bash
cd frontend
npm install
npm run dev
```

### Middleware
```bash
cd middleware
# Crear archivo .env con credenciales de Salesforce
go run main.go
```

### Infrastructure
```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

## Integración con Salesforce

El middleware se conecta a Salesforce usando:
- **Instance URL**: Configurada en `.env`
- **Access Token**: Token de sesión OAuth
- **Apex Endpoint**: `/services/apexrest/B2BLeads/`

