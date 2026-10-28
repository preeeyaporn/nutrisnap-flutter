# NutriSnap - โภชนาการอัจฉริยะ ปลายนิ้วสัมผัส 🥗📱

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Material Design](https://img.shields.io/badge/Material_Design-3-7C3AED?logo=material-design)](https://m3.material.io)
[![Tests](https://img.shields.io/badge/Automated_Tests-103_Passing-22C55E)](https://github.com/preeeyaporn/nutrisnap-flutter)

NutriSnap คือแอปพลิเคชันจัดการโภชนาการและสุขภาพอัจฉริยะ พัฒนาด้วย Flutter (Material Design 3) ที่ผสมผสานเทคโนโลยี **Google Gemini 1.5 Flash AI Vision** และ **Open Food Facts REST API** เข้ากับสถาปัตยกรรม **Clean Architecture / Repository Pattern** เพื่อการวิเคราะห์สารอาหารที่รวดเร็ว แม่นยำ และทำงานได้แบบ **Offline-First**

---

## 🌟 ฟีเจอร์หลักของแอปพลิเคชัน (Key Features)

### 1. 🔐 ระบบยืนยันตัวตนและความปลอดภัย (Authentication & Profiles)
- ระบบ **เข้าสู่ระบบ (Login)** และ **สมัครสมาชิก (Register)** พร้อมการตรวจสอบความถูกต้องของอีเมลและรหัสผ่าน
- ระบบตรวจสอบและป้องกันการเข้าสู่ระบบสำหรับผู้ใช้ที่ยังไม่ลงทะเบียน
- รองรับ **โหมดผู้เยี่ยมชม (Guest Mode)** ให้ทดลองใช้งานได้ทันทีโดยไม่ต้องลงทะเบียน
- จัดเก็บข้อมูลบัญชีผู้ใช้ลงฐานข้อมูล Local Database (Hive + SharedPreferences) ดึงชื่อเดิมกลับมาเมื่อเข้าสู่ระบบใหม่

### 2. 🏠 หน้าหลักแดชบอร์ดโภชนาการ (Home Screen Dashboard)
- การ์ดสรุปคุณค่าทางโภชนาการวันนี้ (Nutrition Summary Card) คำนวณจาก **ข้อมูลจริง (Real Data)**
- สรุปแคลอรี่รวม และสารอาหารหลัก 3 ตัว (Macronutrients: โปรตีน, คาร์บ, ไขมัน)
- สถานะมื้ออาหารล่าสุด (Recent Meals) พร้อมการ์ด Empty State สวยงาม
- ทางลัดเปิดกล้อง AI สแกนอาหาร และสแกนเนอร์บาร์โค้ดผลิตภัณฑ์

### 3. 📷 สแกนอาหารด้วยกล้อง AI (AI Food Camera with Gemini Vision)
- สแกนภาพอาหารสดผ่านกล้องมือถือแบบ Real-time ด้วย CameraPreview
- ประมวลผลและจำแนกเมนูอาหารพร้อมประมาณการแคลอรี่ด้วยเทคโนโลยี **Gemini 1.5 Flash Vision**
- ระบบรองรับโหมดออฟไลน์ (Offline Fallback) สำหรับเมนูยอดนิยมเมื่อไม่มีการเชื่อมต่ออินเทอร์เน็ต

### 4. 🏷️ สแกนบาร์โค้ดผลิตภัณฑ์ (Barcode Scanner)
- ตรวจจับบาร์โค้ดสด (EAN-13 / UPC) เชื่อมต่อกับฐานข้อมูล **Open Food Facts API**
- ค้นหาข้อมูลโภชนาการฉบับเต็ม บันทึกลงสมุดบันทึกอาหารประจำวันได้ทันที

### 5. 🗄️ สถาปัตยกรรมข้อมูลแบบ Offline-First (Local & Cloud Sync)
- ฐานข้อมูลภายในเครื่องประสิทธิภาพสูงด้วย **Hive NoSQL Database**
- รองรับการซิงค์ข้อมูลขึ้น Cloud Firestore สำหรับการสำรองข้อมูลข้ามอุปกรณ์

---

## 🏗️ โครงสร้างสถาปัตยกรรมซอฟต์แวร์ (Architecture)

โปรเจกต์ได้รับการออกแบบตามหลัก **Clean Architecture** และ **Repository Pattern**:

```text
lib/
├── core/                        # โครงสร้างพื้นฐานของระบบ
│   ├── constants/               # ค่าคงที่ API, สี (AppColors), แบบอักษร (Typography)
│   ├── database/                # Local Database (Hive) และ Cloud (Firestore)
│   ├── services/                # บริการภายนอก (Auth, Open Food Facts, Gemini AI)
│   └── utils/                   # Result Pattern สำหรับการจัดการ State แบบ Type-safe
├── features/                    # โมดูลฟีเจอร์แยกตามโดเมน
│   ├── auth/                    # หน้าจอและ Logic ของระบบ Login / Register
│   ├── camera/                  # กล้อง AI และหน้าแสดงผลการวิเคราะห์
│   ├── home/                    # หน้าหลัก Home Dashboard และ Main Shell
│   ├── nutrition/               # การจัดการสารอาหาร และรายละเอียดมื้ออาหาร
│   ├── onboarding/              # หน้า Onboarding แนะนำฟีเจอร์
│   └── splash/                  # หน้าเริ่มต้น Splash Screen พร้อมแอนิเมชัน
└── main.dart                    # จุดเริ่มต้นของแอปพลิเคชันและการตั้งค่า MultiProvider
```

---

## 👥 คณะผู้พัฒนาโปรเจกต์ (Development Team)

| ชื่อ-นามสกุล / GitHub | บทบาทหน้าที่ความรับผิดชอบ (Role & Responsibilities) |
| :--- | :--- |
| **Preeyaporn (Team Lead)** | **Project Lead & Core Architecture**: ออกแบบสถาปัตยกรรมระบบหลัก, ระบบ Authentication (Login/Register), หน้า Home Screen, Local Database (Hive/SharedPreferences), และชุดทดสอบระบบ (Test Suite) |
| **Kunakorn** | **Camera & AI Vision**: พัฒนาระบบกล้อง AI Food Camera, เชื่อมต่อ Gemini 1.5 Flash API และระบบจำแนกภาพอาหาร |
| **Natjama** | **Nutrition Details**: พัฒนารายละเอียดข้อมูลโภชนาการฉบับเต็ม (Full Nutrition Details) และการคำนวณ Macronutrients |
| **Thanut-orn** | **History & Database**: พัฒนาระบบประวัติการสแกนอาหาร (History Logs) และการจัดการฐานข้อมูลบันทึกมื้ออาหาร |

---

## 🚀 วิธีการติดตั้งและรันโปรเจกต์ (Getting Started)

### 1. ดาวน์โหลด Dependencies
```bash
flutter pub get
```

### 2. รันแอปพลิเคชันบนอุปกรณ์ที่ต้องการ
- **รันบน Google Chrome (แนะนำสำหรับพรีวิวบนคอมพิวเตอร์ มีกรอบมือถือ 390x844)**:
  ```bash
  flutter run -d chrome
  ```
- **รันบนมือถือ Android หรือโทรศัพท์จำลอง (Android Emulator)**:
  ```bash
  flutter run
  ```

### 3. ตรวจสอบคุณภาพโค้ดและการทดสอบ (Tests & Quality Verification)
- **รันชุดทดสอบอัตโนมัติทั้งหมด (103/103 Tests Passed)**:
  ```bash
  flutter test
  ```
- **ตรวจสอบ Static Code Analysis (0 issues)**:
  ```bash
  flutter analyze
  ```
