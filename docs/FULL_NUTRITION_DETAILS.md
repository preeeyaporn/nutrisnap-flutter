# Full Nutrition Details (Screen 5) - Architectural & Specification Guide

## 1. ขอบเขตความรับผิดชอบ (Person 3: นัท - Natjama)
รับผิดชอบการพัฒนา **หน้ารายละเอียดโภชนาการฉบับเต็ม (Full Nutrition Details)** ตรงตาม **Figma Screen 5 (`Screen 5 — Barcode Result / รายละเอียดอาหาร`)** ซึ่งประกอบด้วย:
1. การเชื่อมต่อและดึงข้อมูลจาก **Open Food Facts REST API** พร้อมระบบสำรอง (Fallback)
2. แผงสารอาหารหลัก 2x2 Grid พร้อม **Progress Bar แยก 4 สี** (โปรตีน, คาร์โบไฮเดรต, ไขมันรวม, น้ำตาล)
3. ระบบคำนวณตัวเลขแคลอรี่คิดเป็น **เปอร์เซ็นต์ของความต้องการพลังงานต่อวัน (Daily Calorie Target)**
4. วงแหวนไฟ Circular Gauge พร้อมไอคอนเปลวไฟ (🔥)
5. ตัวปรับขนาดหน่วยบริโภคแบบไดนามิก (**Portion Size Adjuster 🥣**) พร้อม Stepper `[-] x1 [+]`
6. การบันทึกมื้ออาหารลงสู่ฐานข้อมูลในเครื่อง (**Hive Database**)

---

## 2. สูตรและหลักการคำนวณโภชนาการ (Calculation Formulas)

### 2.1 การคำนวณตามหน่วยบริโภค (Portion Sizing)
$$\text{Calculated Nutrient} = \text{Base Nutrient} \times \text{Portion Multiplier}$$
* สเกลมาตรฐาน: $x1.0$ (1 หน่วยบริโภคตามฉลาก)
* สเกลปรับลด: $x0.5$ (ทานครึ่งหน่วยบริโภค)
* สเกลปรับเพิ่ม: $x1.5, x2.0, \dots, x5.0$ (ทานเพิ่มตามจำนวนมื้อ)

### 2.2 การคำนวณเปอร์เซ็นต์ความต้องการพลังงานต่อวัน (Daily Calorie %)
$$\%\text{ Daily Target} = \left(\frac{\text{Calculated Calories}}{\text{Daily Calorie Target}}\right) \times 100$$
* ค่าเริ่มต้นตามเกณฑ์ Thai RDI: 2,000 กิโลแคลอรี/วัน (หรือตามที่ผู้ใช้กำหนดในโปรไฟล์)
* โควตาพลังงานคงเหลือ: $\text{Remaining} = \max(0, \text{Daily Target} - \text{Calculated Calories})$

### 2.3 การคำนวณเปอร์เซ็นต์สารอาหารหลักตามเกณฑ์ Thai RDI (อย. ประเทศไทย & WHO)
| สารอาหาร | เกณฑ์อ้างอิงต่อวัน | สีธีมของระบบ | สูตรคำนวณ % |
| :--- | :---: | :---: | :--- |
| **โปรตีน (Protein)** | 50 กรัม | เขียว Emerald (`#10B981`) | $(\text{Protein} / 50\text{ g}) \times 100$ |
| **คาร์โบไฮเดรต (Carbohydrates)** | 300 กรัม | ฟ้า Sky Blue (`#0284C7`) | $(\text{Carbs} / 300\text{ g}) \times 100$ |
| **ไขมันรวม (Total Fat)** | 65 กรัม | แดง Coral (`#EF4444`) | $(\text{Fat} / 65\text{ g}) \times 100$ |
| **น้ำตาล (Sugar)** | ไม่เกิน 24 กรัม (6 ช้อนชา) | ม่วง Purple (`#8B5CF6`) | $(\text{Sugar} / 24\text{ g}) \times 100$ |

### 2.4 การคำนวณสัดส่วนพลังงาน (Atwater System 4-4-9)
* พลังงานจากโปรตีน = $\text{Protein (g)} \times 4\text{ kcal/g}$
* พลังงานจากคาร์โบไฮเดรต = $\text{Carbohydrates (g)} \times 4\text{ kcal/g}$
* พลังงานจากไขมัน = $\text{Fat (g)} \times 9\text{ kcal/g}$
* รวมพลังงานสารอาหารหลัก = $P_{\text{kcal}} + C_{\text{kcal}} + F_{\text{kcal}}$

---

## 3. สถาปัตยกรรมการเชื่อมต่อ Open Food Facts API
```
[Barcode Scanner / User Input]
              │
              ▼
   [OpenFoodFactsService]
     ├── 1. ตรวจสอบ Demo/Verified Catalog (เช่น น้ำมะพร้าว, โยเกิร์ตดัชชี่ 125g, โค้ก, มาม่า)
     └── 2. ยิง Live REST API: world.openfoodfacts.org/api/v0/product/{barcode}.json
              │
              ▼
    [Nutriment Parser]
     ├── ให้ความสำคัญกับค่าต่อ 1 หน่วยบริโภค (_serving) ก่อน (_100g)
     ├── แปลงหน่วยพลังงาน kJ เป็น kcal (1 kcal = 4.184 kJ)
     └── Atwater Fallback (กรณี API ไม่มีค่าแคลอรี่ ให้คำนวณจาก P*4 + C*4 + F*9)
              │
              ▼
  [NutritionDetailScreen] (Figma Screen 5)
```

---

## 4. ผลการทดสอบ (Automated Test Suites)
* `test/widget/nutrition_detail_screen_test.dart` (5 tests)
* `test/unit/services/open_food_facts_service_test.dart` (Unit tests)
* `test/unit/models/food_item_test.dart` (Calculation unit tests)
* ทั้งหมดผ่านการตรวจสอบ 100% Green
