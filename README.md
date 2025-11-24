# Jisr Al-Lawziyah (منتجع جسر اللوزية)

نسخة مُنظَّمة وفاخرة من واجهة تطبيق المنتجع مبنية بـ SwiftUI. هذا المستودع يحوي مشروع تطبيق واجهة المستخدم مع دعم Theme و Config وأصول (Assets).

---

## ماذا يحتوي هذا المشروع؟
- `Sources/` — كود SwiftUI (شاشات، مكونات، مدراء).
- `Sources/Theme.swift` — تعاريف الألوان والخطوط الموحدة للتصميم الفاخر.
- `Sources/AppConfig.swift` — إعدادات قابلة للتعديل مثل روابط التواصل وأسماء الأصول.
- `Assets.xcassets` — أيقونات وشعارات المشروع (اضف الملفات بحسب ASSETS_MANIFEST.json).
- `ASSETS_MANIFEST.json` — قائمة الأصول المطلوبة (أسماء وأحجام مقترحة).
- `README.md` — هذا الملف.

## متطلبات قبل التشغيل
1. افتح المشروع في Xcode (يفضل Xcode 14+).
2. أضف ملفات `Theme.swift` و`AppConfig.swift` إلى مجلد `Sources`.
3. ضع أيقونات العلامة التجارية في `Assets.xcassets` بالأسماء الموجودة في `ASSETS_MANIFEST.json`.
4. تأكد من ضبط Signing & Capabilities إذا أردت تشغيله على جهاز فعلي.

## أوامر Git (محلي)
```bash
git add .
git commit -m "Add theme, config and assets manifest"
git push origin main
