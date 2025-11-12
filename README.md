# 🛒 Hackathon Mercadona 2025

Aplicación móvil desarrollada durante el Hackathon de la UPV en colaboración con Mercadona. Una experiencia de compra inteligente e innovadora que combina catálogo de productos, asistente AI y navegación optimizada en tienda.

## 📱 Características Principales

### 🏪 Catálogo de Productos
- Exploración completa del catálogo de productos de Mercadona
- Búsqueda y filtrado por categorías
- Gestión de productos favoritos
- Añadir productos al carrito con cantidades personalizables
- Visualización de precios y ofertas especiales
- Historial de pedidos

### 🤖 Cora - Asistente Virtual AI
- Asistente conversacional inteligente impulsado por IA
- Recomendaciones personalizadas de productos
- Ayuda con la lista de la compra
- Respuestas a preguntas sobre productos
- Sugerencias basadas en preferencias del usuario

### 🗺️ SmartPath - Navegación Inteligente
- Mapa interactivo de la tienda Mercadona
- Cálculo automático de la ruta óptima para recoger productos
- Visualización de la ubicación de cada producto en la tienda
- Orden de visita optimizado para ahorrar tiempo
- Indicación clara del recorrido a seguir

## 🛠️ Tecnologías Utilizadas

- **SwiftUI**: Framework moderno para la interfaz de usuario
- **SwiftData**: Persistencia local de datos
- **OpenAI API**: Integración con ChatGPT para el asistente virtual Cora
- **MVVM Architecture**: Arquitectura Model-View-ViewModel para mejor organización del código

## 📋 Requisitos

- iOS 17.0 o superior
- Xcode 15.0 o superior
- Swift 5.9+
- Cuenta de OpenAI API (para funcionalidad de Cora)

## 🚀 Instalación

1. Clona el repositorio:
```bash
git clone https://github.com/yares28/Hackathon-Mercadona.git
cd Hackathon-Mercadona
```

2. Abre el proyecto en Xcode:
```bash
open Hackathon2025.xcodeproj
```

3. Configura tu API Key de OpenAI:
   - Crea una copia del archivo de configuración:
   ```bash
   cp Hackathon2025/Config/APIKeys.swift.example Hackathon2025/Config/APIKeys.swift
   ```
   - Edita `Hackathon2025/Config/APIKeys.swift` y reemplaza `"TU_API_KEY_AQUI"` con tu API key de OpenAI
   - Puedes obtener tu API key en: https://platform.openai.com/api-keys

4. Compila y ejecuta el proyecto en el simulador o dispositivo iOS

## 📁 Estructura del Proyecto

```
Hackathon2025/
├── Models/              # Modelos de datos
│   ├── Product.swift
│   ├── Basket.swift
│   ├── CartEntry.swift
│   ├── Order.swift
│   └── AIMessage.swift
├── Views/               # Vistas de la aplicación
│   ├── MainView.swift
│   ├── Catalog/        # Catálogo de productos
│   ├── MercAI/         # Asistente virtual Cora
│   ├── SmartPath/      # Navegación en tienda
│   ├── Cart/           # Carrito de compra
│   ├── Favorites/      # Productos favoritos
│   └── ProductDetail/  # Detalle de producto
├── ViewModels/          # Lógica de negocio
│   ├── ProductsViewModel.swift
│   └── MercAIViewModel.swift
├── Services/            # Servicios externos
│   ├── AIService.swift
│   └── ChatGPTService.swift
├── Config/              # Configuración
│   └── APIKeys.swift
└── Assets.xcassets/     # Recursos e imágenes
```

## 👥 Equipo de Desarrollo

Proyecto desarrollado durante el Hackathon UPV 2025 en colaboración con Mercadona.

## ⚠️ Notas Importantes

- **Seguridad**: El archivo `APIKeys.swift` está en `.gitignore` para proteger tus credenciales. Nunca compartas tu API key públicamente.
- **Demo**: La funcionalidad SmartPath utiliza datos de demostración del mapa de tienda.
- **Productos**: El catálogo incluye productos reales de Mercadona con imágenes y precios de referencia.

## 📄 Licencia

Este proyecto fue desarrollado como parte de un Hackathon educativo en la UPV.

## 🙏 Agradecimientos

- Universidad Politécnica de Valencia (UPV)
- Mercadona por su colaboración
- OpenAI por la API de ChatGPT

