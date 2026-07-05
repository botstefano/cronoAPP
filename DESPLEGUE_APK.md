# Configuración de Keystore para APK Android

## Paso 1: Generar Keystore

Ejecutar este comando en la terminal (en el directorio flutter_app/android):

```bash
keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

**Durante el proceso te pedirá:**
- Contraseña del keystore (anótala)
- Nombre, organización, etc. (puedes poner lo que quieras)
- Contraseña de la clave (puede ser la misma del keystore)

## Paso 2: Crear archivo key.properties

Crear archivo `flutter_app/android/key.properties` con el siguiente contenido:

```properties
storePassword=TU_CONTRASEÑA_KEystore
keyPassword=TU_CONTRASEÑA_KEystore
keyAlias=key
storeFile=key.jks
```

## Paso 3: Configurar build.gradle

Editar `flutter_app/android/app/build.gradle.kts`:

```kotlin
// Agregar al inicio del archivo
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... configuración existente ...

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## Paso 4: Generar APK Release

```bash
cd flutter_app
flutter build apk --release
```

El APK se generará en: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

## ⚠️ IMPORTANTE

- **Nunca** subas `key.jks` ni `key.properties` a GitHub
- **Nunca** compartas tu contraseña del keystore
- **Guarda** el archivo `key.jks` en un lugar seguro
- **Si pierdes** el keystore, no podrás actualizar la app en Google Play
