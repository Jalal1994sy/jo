
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.jouwdriver.app',
  appName: 'Jouw Driver',
  webDir: 'out',
  server: {
    // IMPORTANT: Replace this with your actual deployed Next.js production URL
    // Example: 'https://jouwdriver.yourdomain.com'
    url: 'https://your-production-domain.com',
    cleartext: true,
    androidScheme: 'https',
    iosScheme: 'https',
    allowNavigation: ['*.your-production-domain.com'],
  },
  android: {
    allowMixedContent: true,
    captureInput: true,
    webContentsDebuggingEnabled: false,
    backgroundColor: '#020817',
    minWebViewVersion: 60,
    buildOptions: {
      keystorePath: undefined,
      keystoreAlias: undefined,
      keystorePassword: undefined,
      keystoreAliasPassword: undefined,
      releaseType: 'APK',
    },
  },
  ios: {
    contentInset: 'automatic',
    backgroundColor: '#020817',
    preferredContentMode: 'mobile',
    scrollEnabled: true,
    limitsNavigationsToAppBoundDomains: false,
    allowsLinkPreview: false,
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2500,
      launchAutoHide: true,
      backgroundColor: '#020817',
      androidSplashResourceName: 'splash',
      androidScaleType: 'CENTER_CROP',
      showSpinner: false,
      splashFullScreen: true,
      splashImmersive: true,
    },
    StatusBar: {
      style: 'Dark',
      backgroundColor: '#020817',
      overlaysWebView: false,
    },
    PushNotifications: {
      presentationOptions: ['badge', 'sound', 'alert'],
    },
    Geolocation: {
      permissions: {
        android: {
          ACCESS_COARSE_LOCATION: true,
          ACCESS_FINE_LOCATION: true,
          ACCESS_BACKGROUND_LOCATION: true,
        },
      },
    },
    Keyboard: {
      resize: 'body',
      style: 'dark',
      resizeOnFullScreen: true,
    },
    LocalNotifications: {
      smallIcon: 'ic_stat_icon_config_sample',
      iconColor: '#D4AF37',
      sound: 'beep.wav',
    },
  },
};

export default config;
