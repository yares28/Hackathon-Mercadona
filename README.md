# 🛒 Hackathon Mercadona 2025

App para iPhone hecha durante el Hackathon de la UPV con Mercadona. Básicamente, hace la compra más fácil y rápida.

## 📱 ¿Qué hace la app?

### 🏪 Catálogo de Productos
Puedes ver todos los productos de Mercadona, buscar lo que necesites, guardar tus favoritos y añadirlos al carrito. También puedes ver tu historial de pedidos anteriores.

### 🤖 Cora - Tu asistente personal
Es como hablar por chat con alguien que te ayuda a hacer la compra. Le puedes preguntar cosas tipo "¿qué necesito para hacer una tortilla?" o "recomiéndame algo para cenar" y te ayuda a encontrar productos.

### 🗺️ SmartPath - Encuentra todo rápido
Te muestra el mapa de la tienda y te dice por dónde ir para coger todos tus productos en el orden más rápido. Así no tienes que dar vueltas buscando las cosas.

## 🛠️ Hecha con

- SwiftUI para la interfaz (el lenguaje de Apple para hacer apps de iPhone)
- SwiftData para guardar tus datos
- ChatGPT para que Cora pueda hablar contigo

## 📋 Lo que necesitas

- Un iPhone con iOS 17 o más nuevo
- Xcode (el programa para hacer apps de iPhone)
- Una API key de OpenAI (gratis para probar, necesaria solo para Cora)

## 🚀 Cómo usar el proyecto

1. Descarga el proyecto a tu ordenador:
```bash
git clone https://github.com/yares28/Hackathon-Mercadona.git
```

2. Abre el archivo `Hackathon2025.xcodeproj` con Xcode

3. Para que funcione Cora (el chat), necesitas:
   - Ir a https://platform.openai.com/api-keys y crear una API key
   - Abrir el archivo `Hackathon2025/Config/APIKeys.swift`
   - Cambiar `"TU_API_KEY_AQUI"` por tu clave

4. Dale al botón de play en Xcode y ya está

## 📁 Cómo está organizado el código

```
Hackathon2025/
├── Models/              # Los datos (productos, carrito, etc)
├── Views/               # Las pantallas de la app
│   ├── Catalog/        # Catálogo de productos
│   ├── MercAI/         # Chat con Cora
│   ├── SmartPath/      # Mapa de la tienda
│   ├── Cart/           # Tu carrito
│   └── Favorites/      # Tus favoritos
├── ViewModels/          # La lógica de la app
├── Services/            # Conexión con ChatGPT
└── Assets.xcassets/     # Imágenes de los productos
```

## 👥 El equipo

Hecho por estudiantes de la UPV durante el Hackathon con Mercadona.

## ⚠️ Cosas a tener en cuenta

- **Tu API key es privada**: No la compartas con nadie ni la subas a internet
- **SmartPath es una demo**: El mapa de la tienda es de ejemplo
- **Los productos son reales**: Pero los precios pueden variar

## 🙏 Gracias a

- La UPV por organizar el Hackathon
- Mercadona por colaborar con nosotros
- OpenAI por dejar usar ChatGPT
