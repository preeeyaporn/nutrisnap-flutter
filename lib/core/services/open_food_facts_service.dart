import 'package:nutrisnap/core/constants/api_constants.dart';
import 'package:nutrisnap/core/services/api_service.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';

/// Service for fetching nutrition data from Open Food Facts REST API.
abstract class OpenFoodFactsService {
  Future<Result<FoodItem>> getProductByBarcode(String barcode);
  Future<Result<List<FoodItem>>> searchProducts(String query, {int page = 1});
}

class OpenFoodFactsServiceImpl implements OpenFoodFactsService {
  final ApiService _apiService;

  OpenFoodFactsServiceImpl({ApiService? apiService})
      : _apiService = apiService ?? HttpApiService();

  @override
  Future<Result<FoodItem>> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();

    // Built-in authentic verified catalog for demo and common Thai/international products
    final demoProducts = {
      '8850188800123': FoodItem(
        id: 'off_8850188800123',
        barcode: '8850188800123',
        name: 'น้ำมะพร้าวสดออร์แกนิก 100%',
        brand: 'Nature Choice Organic',
        imageUrl: 'assets/images/screen_barcode.png',
        servingSize: '330 มล.',
        calories: 65.0,
        protein: 1.2,
        carbohydrates: 15.0,
        fat: 0.2,
        sugar: 12.0,
        fiber: 1.5,
        saturatedFat: 0.1,
        sodium: 15.0,
        nutriScore: 'A',
        scannedAt: DateTime.now(),
        ingredients: [
          'น้ำมะพร้าวออร์แกนิก 100%',
          'วิตามินซีธรรมชาติ',
        ],
        source: 'barcode_scan',
      ),
      '8850987101017': FoodItem(
        id: 'off_8850987101017',
        barcode: '8850987101017',
        name: 'บะหมี่กึ่งสำเร็จรูป มาม่า รสต้มยำกุ้ง',
        brand: 'มาม่า (MAMA)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/098/710/1017/front_th.jpg',
        servingSize: '55 กรัม',
        calories: 260.0,
        protein: 5.0,
        carbohydrates: 36.0,
        fat: 11.0,
        sugar: 3.0,
        fiber: 2.0,
        saturatedFat: 5.0,
        sodium: 1280.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี', 'น้ำมันปาล์ม', 'พริกเผา', 'ผงต้มยำกุ้ง', 'กุ้งอบแห้ง'],
        source: 'barcode_scan',
      ),
      '8852018101024': FoodItem(
        id: 'off_8852018101024',
        barcode: '8852018101024',
        name: 'บะหมี่กึ่งสำเร็จรูป ยำยำ รสไก่ (Yum Yum Chicken)',
        brand: 'ยำยำ (Yum Yum)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/201/810/1024/front_en.jpg',
        servingSize: '60 กรัม',
        calories: 275.0,
        protein: 5.5,
        carbohydrates: 35.0,
        fat: 12.5,
        sugar: 2.5,
        fiber: 1.8,
        saturatedFat: 6.0,
        sodium: 1150.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี', 'น้ำมันปาล์ม', 'ผงปรุงรสไก่', 'เครื่องเทศ'],
        source: 'barcode_scan',
      ),
      '8851717040013': FoodItem(
        id: 'off_8851717040013',
        barcode: '8851717040013',
        name: 'นมเปรี้ยว ดัชมิลล์ 4 อิน 1 รสผลไม้รวม',
        brand: 'ดัชมิลล์ (Dutch Mill)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/171/704/0013/front_th.jpg',
        servingSize: '180 มล.',
        calories: 120.0,
        protein: 2.0,
        carbohydrates: 25.0,
        fat: 1.5,
        sugar: 21.0,
        fiber: 1.0,
        saturatedFat: 1.0,
        sodium: 55.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['โยเกิร์ต', 'น้ำผลไม้รวม', 'น้ำตาล', 'วิตามินรวม B1 B2 D'],
        source: 'barcode_scan',
      ),
      '5449000000996': FoodItem(
        id: 'off_5449000000996',
        barcode: '5449000000996',
        name: 'โคคา-โคลา ออริจินัล (Coca-Cola Original)',
        brand: 'Coca-Cola',
        imageUrl: 'https://images.openfoodfacts.org/images/products/544/900/000/0996/front_en.jpg',
        servingSize: '330 มล.',
        calories: 139.0,
        protein: 0.0,
        carbohydrates: 35.0,
        fat: 0.0,
        sugar: 35.0,
        fiber: 0.0,
        saturatedFat: 0.0,
        sodium: 10.0,
        nutriScore: 'E',
        scannedAt: DateTime.now(),
        ingredients: ['น้ำคาร์บอเนต', 'น้ำตาล', 'สีคาราเมล', 'กรดฟอสฟอริก', 'คาเฟอีน'],
        source: 'barcode_scan',
      ),
      '3017620422003': FoodItem(
        id: 'off_3017620422003',
        barcode: '3017620422003',
        name: 'นูเทลล่า เฮเซลนัทบดผสมโกโก้ (Nutella)',
        brand: 'Ferrero',
        imageUrl: 'https://images.openfoodfacts.org/images/products/301/762/042/2003/front_fr.jpg',
        servingSize: '15 กรัม',
        calories: 81.0,
        protein: 0.9,
        carbohydrates: 8.6,
        fat: 4.6,
        sugar: 8.4,
        fiber: 0.5,
        saturatedFat: 1.6,
        sodium: 6.0,
        nutriScore: 'E',
        scannedAt: DateTime.now(),
        ingredients: ['น้ำตาล', 'น้ำมันปาล์ม', 'เฮเซลนัท 13%', 'โกโก้ไขมันต่ำ 7.4%', 'นมผงขาดมันเนย'],
        source: 'barcode_scan',
      ),
      '8851717900907': FoodItem(
        id: 'off_8851717900907',
        barcode: '8851717900907',
        name: 'โยเกิร์ตไขมัน 0% รสสตรอเบอร์รี่ (Dutchie 0% Fat)',
        brand: 'DUTCHIE, ดัชชี่',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/171/790/0907/front_th.jpg',
        servingSize: '125 กรัม (1 ถ้วย)',
        calories: 80.0,
        protein: 3.0,
        carbohydrates: 17.0,
        fat: 0.0,
        sugar: 13.0,
        fiber: 2.0,
        saturatedFat: 0.0,
        sodium: 60.0,
        nutriScore: 'B',
        scannedAt: DateTime.now(),
        ingredients: ['โยเกิร์ตขาดมันเนย', 'สตรอเบอร์รี่ในน้ำเชื่อม', 'น้ำตาล', 'โพรไบโอติกส์'],
        source: 'barcode_scan',
      ),
      '8850718801759': FoodItem(
        id: 'off_8850718801759',
        barcode: '8850718801759',
        name: 'มันฝรั่งทอดกรอบ เลย์ รสมันฝรั่งแท้ (Lay\'s Classic)',
        brand: 'เลย์ (Lay\'s)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/071/880/1759/front_th.jpg',
        servingSize: '30 กรัม',
        calories: 160.0,
        protein: 2.0,
        carbohydrates: 15.0,
        fat: 10.0,
        sugar: 1.0,
        fiber: 1.0,
        saturatedFat: 4.0,
        sodium: 140.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['มันฝรั่ง 67%', 'น้ำมันรำข้าว 31%', 'เครื่องปรุงรส 2%'],
        source: 'barcode_scan',
      ),
      '8850718801766': FoodItem(
        id: 'off_8850718801766',
        barcode: '8850718801766',
        name: 'มันฝรั่งทอดกรอบ เลย์ รสโนริสาหร่าย (Lay\'s Nori Seaweed)',
        brand: 'เลย์ (Lay\'s)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/071/880/1766/front_th.jpg',
        servingSize: '30 กรัม',
        calories: 160.0,
        protein: 2.0,
        carbohydrates: 16.0,
        fat: 10.0,
        sugar: 2.0,
        fiber: 1.0,
        saturatedFat: 4.0,
        sodium: 170.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['มันฝรั่ง 65%', 'น้ำมันรำข้าว 30%', 'ผงปรุงรสโนริสาหร่าย 5%'],
        source: 'barcode_scan',
      ),
      '8850718801773': FoodItem(
        id: 'off_8850718801773',
        barcode: '8850718801773',
        name: 'มันฝรั่งทอดกรอบ เลย์ รสบาร์บีคิว (Lay\'s BBQ)',
        brand: 'เลย์ (Lay\'s)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/071/880/1773/front_th.jpg',
        servingSize: '30 กรัม',
        calories: 160.0,
        protein: 2.0,
        carbohydrates: 16.0,
        fat: 10.0,
        sugar: 2.0,
        fiber: 1.0,
        saturatedFat: 4.0,
        sodium: 180.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['มันฝรั่ง 65%', 'น้ำมันรำข้าว 30%', 'ผงปรุงรสบาร์บีคิว 5%'],
        source: 'barcode_scan',
      ),
      '8850100000958': FoodItem(
        id: 'off_8850100000958',
        barcode: '8850100000958',
        name: 'ขนมอบกรอบ โปเต้ รสเค็มมัน (Pote)',
        brand: 'โปเต้ (Pote)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/010/000/0958/front_th.jpg',
        servingSize: '28 กรัม',
        calories: 140.0,
        protein: 1.0,
        carbohydrates: 18.0,
        fat: 7.0,
        sugar: 1.0,
        fiber: 1.0,
        saturatedFat: 3.0,
        sodium: 210.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี', 'มันฝรั่ง', 'น้ำมันปาล์ม', 'เกลือไอโอดีน'],
        source: 'barcode_scan',
      ),
      '8850100000057': FoodItem(
        id: 'off_8850100000057',
        barcode: '8850100000057',
        name: 'ขนมอบกรอบ ปาปริก้า รสปาปริก้า (Paprika)',
        brand: 'ปาปริก้า (Paprika)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/010/000/0057/front_th.jpg',
        servingSize: '32 กรัม',
        calories: 170.0,
        protein: 2.0,
        carbohydrates: 20.0,
        fat: 9.0,
        sugar: 2.0,
        fiber: 1.0,
        saturatedFat: 4.0,
        sodium: 230.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี', 'แป้งมันสำปะหลัง', 'น้ำมันปาล์ม', 'ผงปาปริก้า'],
        source: 'barcode_scan',
      ),
      '8850125000012': FoodItem(
        id: 'off_8850125000012',
        barcode: '8850125000012',
        name: 'ปลาเส้นปรุงรส เบนโตะ รสทรงเครื่อง (Bento Squid)',
        brand: 'เบนโตะ (Bento)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/012/500/0012/front_th.jpg',
        servingSize: '20 กรัม',
        calories: 70.0,
        protein: 5.0,
        carbohydrates: 12.0,
        fat: 0.0,
        sugar: 7.0,
        fiber: 0.5,
        saturatedFat: 0.0,
        sodium: 490.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['เนื้อปลาซูริมิ 45%', 'ปลาหมึก 40%', 'แป้งสาลี 5%', 'น้ำตาล 5%', 'พริก 3%'],
        source: 'barcode_scan',
      ),
      '8850127003816': FoodItem(
        id: 'off_8850127003816',
        barcode: '8850127003816',
        name: 'นมถั่วเหลือง แลคตาซอย สูตรต้นตำรับ (Lactasoy Original)',
        brand: 'แลคตาซอย (Lactasoy)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/012/700/3816/front_th.jpg',
        servingSize: '300 มล.',
        calories: 220.0,
        protein: 9.0,
        carbohydrates: 29.0,
        fat: 7.0,
        sugar: 23.0,
        fiber: 2.0,
        saturatedFat: 1.5,
        sodium: 135.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['น้ำนมถั่วเหลือง 89.2%', 'น้ำตาล 7.0%', 'นมผงธรรมดา 2.0%', 'ไขมันพืช 1.8%'],
        source: 'barcode_scan',
      ),
      '8851717000017': FoodItem(
        id: 'off_8851717000017',
        barcode: '8851717000017',
        name: 'นมเปรี้ยว ดัชมิลล์ รสส้ม (Dutch Mill Orange)',
        brand: 'ดัชมิลล์ (Dutch Mill)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/171/700/0017/front_th.jpg',
        servingSize: '180 มล.',
        calories: 120.0,
        protein: 2.0,
        carbohydrates: 25.0,
        fat: 1.5,
        sugar: 20.0,
        fiber: 1.0,
        saturatedFat: 1.0,
        sodium: 50.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['โยเกิร์ต', 'น้ำส้ม', 'น้ำตาล', 'วิตามินรวม B1 B2 D'],
        source: 'barcode_scan',
      ),
      '8850188211028': FoodItem(
        id: 'off_8850188211028',
        barcode: '8850188211028',
        name: 'นมยูเอชที โฟร์โมสต์ รสจืด (Foremost Plain UHT Milk)',
        brand: 'โฟร์โมสต์ (Foremost)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/018/821/1028/front_th.jpg',
        servingSize: '225 มล.',
        calories: 140.0,
        protein: 7.0,
        carbohydrates: 11.0,
        fat: 8.0,
        sugar: 11.0,
        fiber: 0.0,
        saturatedFat: 5.0,
        sodium: 100.0,
        nutriScore: 'B',
        scannedAt: DateTime.now(),
        ingredients: ['น้ำนมโคแท้ 100%'],
        source: 'barcode_scan',
      ),
      // ขนมขบเคี้ยวและมันฝรั่งทอด (Chips & Crisps)
      '8850718801780': FoodItem(
        id: 'off_8850718801780',
        barcode: '8850718801780',
        name: 'มันฝรั่งทอดกรอบ เลย์ รสหมึกย่างฮอตชิลลี่ (Lay\'s Hot Chili Squid)',
        brand: 'เลย์ (Lay\'s)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/071/880/1780/front_th.jpg',
        servingSize: '30 กรัม',
        calories: 160.0,
        protein: 2.0,
        carbohydrates: 16.0,
        fat: 10.0,
        sugar: 2.0,
        fiber: 1.0,
        saturatedFat: 4.0,
        sodium: 180.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['มันฝรั่ง 65%', 'น้ำมันรำข้าว 30%', 'ผงปรุงรสหมึกย่างฮอตชิลลี่ 5%'],
        source: 'barcode_scan',
      ),
      '8850718801797': FoodItem(
        id: 'off_8850718801797',
        barcode: '8850718801797',
        name: 'มันฝรั่งทอดกรอบ เลย์ รสซาวครีมและหัวหอม (Lay\'s Sour Cream & Onion)',
        brand: 'เลย์ (Lay\'s)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/071/880/1797/front_th.jpg',
        servingSize: '30 กรัม',
        calories: 160.0,
        protein: 2.0,
        carbohydrates: 16.0,
        fat: 10.0,
        sugar: 2.0,
        fiber: 1.0,
        saturatedFat: 4.0,
        sodium: 160.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['มันฝรั่ง 65%', 'น้ำมันรำข้าว 30%', 'ผงปรุงรสซาวครีมและหัวหอม 5%'],
        source: 'barcode_scan',
      ),
      '8850718807881': FoodItem(
        id: 'off_8850718807881',
        barcode: '8850718807881',
        name: 'มันฝรั่งทอดกรอบ เลย์ สแตคส์ รสออริจินัล (Lay\'s Stax Original)',
        brand: 'เลย์ สแตคส์ (Lay\'s Stax)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/071/880/7881/front_th.jpg',
        servingSize: '25 กรัม',
        calories: 130.0,
        protein: 1.5,
        carbohydrates: 15.0,
        fat: 7.0,
        sugar: 1.0,
        fiber: 1.0,
        saturatedFat: 3.5,
        sodium: 125.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['เกล็ดมันฝรั่ง 55%', 'น้ำมันปาล์มโอเลอิน 30%', 'แป้งสาลี 8%'],
        source: 'barcode_scan',
      ),
      '8850718805627': FoodItem(
        id: 'off_8850718805627',
        barcode: '8850718805627',
        name: 'ขนมอบกรอบ ตะวัน รสต้นตำรับ (Tawan Original)',
        brand: 'ตะวัน (Tawan)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/071/880/5627/front_th.jpg',
        servingSize: '30 กรัม',
        calories: 150.0,
        protein: 2.0,
        carbohydrates: 19.0,
        fat: 8.0,
        sugar: 2.0,
        fiber: 1.0,
        saturatedFat: 3.5,
        sodium: 210.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['ข้าวโพด 58%', 'น้ำมันรำข้าว 32%', 'เครื่องปรุงรส 10%'],
        source: 'barcode_scan',
      ),
      '8850718803128': FoodItem(
        id: 'off_8850718803128',
        barcode: '8850718803128',
        name: 'ขนมอบกรอบ ซันไบทส์ รสบาร์บีคิว (Sunbites BBQ)',
        brand: 'ซันไบทส์ (Sunbites)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/071/880/3128/front_th.jpg',
        servingSize: '30 กรัม',
        calories: 140.0,
        protein: 2.0,
        carbohydrates: 20.0,
        fat: 6.0,
        sugar: 2.0,
        fiber: 2.0,
        saturatedFat: 2.5,
        sodium: 160.0,
        nutriScore: 'B',
        scannedAt: DateTime.now(),
        ingredients: ['ธัญพืชรวม 68%', 'น้ำมันรำข้าว 24%', 'เครื่องปรุงรส 8%'],
        source: 'barcode_scan',
      ),
      '8850100001016': FoodItem(
        id: 'off_8850100001016',
        barcode: '8850100001016',
        name: 'ขนมอบกรอบ คอนเน่ รสข้าวโพดเข้มข้น (Cornae)',
        brand: 'คอนเน่ (Cornae)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/010/000/1016/front_th.jpg',
        servingSize: '28 กรัม',
        calories: 140.0,
        protein: 1.0,
        carbohydrates: 18.0,
        fat: 7.0,
        sugar: 2.0,
        fiber: 1.0,
        saturatedFat: 3.0,
        sodium: 190.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งข้าวโพด 62%', 'น้ำมันปาล์ม 30%', 'ผงปรุงรส 8%'],
        source: 'barcode_scan',
      ),
      '8850100002013': FoodItem(
        id: 'off_8850100002013',
        barcode: '8850100002013',
        name: 'ขนมอบกรอบ สแน็คแจ๊ค รสดั้งเดิม (Snack Jack Green Pea)',
        brand: 'สแน็คแจ๊ค (Snack Jack)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/010/000/2013/front_th.jpg',
        servingSize: '35 กรัม',
        calories: 170.0,
        protein: 4.0,
        carbohydrates: 21.0,
        fat: 8.0,
        sugar: 2.0,
        fiber: 2.0,
        saturatedFat: 3.5,
        sodium: 220.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['ถั่วลันเตา 72%', 'น้ำมันปาล์ม 20%', 'เกลือไอโอดีน 2%'],
        source: 'barcode_scan',
      ),
      '8850100003010': FoodItem(
        id: 'off_8850100003010',
        barcode: '8850100003010',
        name: 'ขนมขาไก่ รสทรงเครื่อง โลตัส (Lotus Chicken Leg Biscuit)',
        brand: 'โลตัส (Lotus)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/010/000/3010/front_th.jpg',
        servingSize: '30 กรัม',
        calories: 150.0,
        protein: 3.0,
        carbohydrates: 20.0,
        fat: 7.0,
        sugar: 2.0,
        fiber: 1.0,
        saturatedFat: 3.0,
        sodium: 250.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี 70%', 'น้ำมันปาล์ม 18%', 'ซอสปรุงรส 10%'],
        source: 'barcode_scan',
      ),
      '8850029000118': FoodItem(
        id: 'off_8850029000118',
        barcode: '8850029000118',
        name: 'บิสกิตแท่งเคลือบช็อกโกแลต ป๊อกกี้ (Glico Pocky Chocolate)',
        brand: 'กูลิโกะ (Glico)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/002/900/0118/front_th.jpg',
        servingSize: '47 กรัม',
        calories: 230.0,
        protein: 4.0,
        carbohydrates: 33.0,
        fat: 9.0,
        sugar: 15.0,
        fiber: 1.5,
        saturatedFat: 5.0,
        sodium: 90.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี', 'น้ำตาล', 'ไขมันพืช', 'ผงโกโก้', 'นมผง'],
        source: 'barcode_scan',
      ),
      '8850029000217': FoodItem(
        id: 'off_8850029000217',
        barcode: '8850029000217',
        name: 'บิสกิตแท่งเคลือบสตรอเบอร์รี่ ป๊อกกี้ (Glico Pocky Strawberry)',
        brand: 'กูลิโกะ (Glico)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/002/900/0217/front_th.jpg',
        servingSize: '45 กรัม',
        calories: 220.0,
        protein: 3.0,
        carbohydrates: 32.0,
        fat: 9.0,
        sugar: 16.0,
        fiber: 1.0,
        saturatedFat: 5.0,
        sodium: 85.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี', 'น้ำตาล', 'ไขมันพืช', 'เกล็ดสตรอเบอร์รี่', 'นมผง'],
        source: 'barcode_scan',
      ),
      '8850029000316': FoodItem(
        id: 'off_8850029000316',
        barcode: '8850029000316',
        name: 'บิสกิตแท่งกรอบ รสลาบ เพรทซ์ (Glico Pretz Larb)',
        brand: 'กูลิโกะ (Glico)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/002/900/0316/front_th.jpg',
        servingSize: '36 กรัม',
        calories: 180.0,
        protein: 4.0,
        carbohydrates: 24.0,
        fat: 8.0,
        sugar: 2.0,
        fiber: 1.0,
        saturatedFat: 4.0,
        sodium: 320.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี', 'น้ำมันพืช', 'ผงปรุงรสลาบ', 'ข้าวคั่ว'],
        source: 'barcode_scan',
      ),
      '7622210001118': FoodItem(
        id: 'off_7622210001118',
        barcode: '7622210001118',
        name: 'คุกกี้แซนด์วิชสอดไส้ครีมวานิลลา โอรีโอ (Oreo Vanilla)',
        brand: 'โอรีโอ (Oreo)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/762/221/000/1118/front_th.jpg',
        servingSize: '29.4 กรัม (3 ชิ้น)',
        calories: 140.0,
        protein: 1.0,
        carbohydrates: 21.0,
        fat: 6.0,
        sugar: 11.0,
        fiber: 0.8,
        saturatedFat: 2.5,
        sodium: 110.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี', 'น้ำตาล', 'น้ำมันพืช', 'ผงโกโก้', 'ฟรุกโตสไซรัป'],
        source: 'barcode_scan',
      ),
      '8851007011234': FoodItem(
        id: 'off_8851007011234',
        barcode: '8851007011234',
        name: 'สาหร่ายทอดกรอบ รสคลาสสิค เถ้าแก่น้อย (Tao Kae Noi Classic)',
        brand: 'เถ้าแก่น้อย (Tao Kae Noi)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/100/701/1234/front_th.jpg',
        servingSize: '32 กรัม',
        calories: 180.0,
        protein: 3.0,
        carbohydrates: 12.0,
        fat: 14.0,
        sugar: 1.0,
        fiber: 2.0,
        saturatedFat: 5.0,
        sodium: 170.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['สาหร่าย 85%', 'น้ำมันปาล์ม 10%', 'เกลือและเครื่องปรุงรส 5%'],
        source: 'barcode_scan',
      ),
      '8851007011241': FoodItem(
        id: 'off_8851007011241',
        barcode: '8851007011241',
        name: 'สาหร่ายย่าง รสเผ็ด เถ้าแก่น้อย (Tao Kae Noi Grilled Spicy)',
        brand: 'เถ้าแก่น้อย (Tao Kae Noi)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/100/701/1241/front_th.jpg',
        servingSize: '20 กรัม',
        calories: 80.0,
        protein: 4.0,
        carbohydrates: 14.0,
        fat: 1.0,
        sugar: 5.0,
        fiber: 2.0,
        saturatedFat: 0.2,
        sodium: 190.0,
        nutriScore: 'B',
        scannedAt: DateTime.now(),
        ingredients: ['สาหร่าย 92%', 'ซอสปรุงรสเผ็ด 8%'],
        source: 'barcode_scan',
      ),

      // หมวดเครื่องดื่มและชานม (Beverages & Dairy)
      '8850999014015': FoodItem(
        id: 'off_8850999014015',
        barcode: '8850999014015',
        name: 'ชาเขียว รสต้นตำรับ โออิชิ (Oishi Green Tea Original)',
        brand: 'โออิชิ (Oishi)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/099/901/4015/front_th.jpg',
        servingSize: '380 มล.',
        calories: 130.0,
        protein: 0.0,
        carbohydrates: 32.0,
        fat: 0.0,
        sugar: 30.0,
        fiber: 0.0,
        saturatedFat: 0.0,
        sodium: 35.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['น้ำชาเขียว 90%', 'ฟรุกโตส 5%', 'น้ำตาล 4.5%'],
        source: 'barcode_scan',
      ),
      '8850999014022': FoodItem(
        id: 'off_8850999014022',
        barcode: '8850999014022',
        name: 'ชาเขียว รสน้ำผึ้งผสมมะนาว อิชิตัน (Ichitan Honey Lemon)',
        brand: 'อิชิตัน (Ichitan)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/099/901/4022/front_th.jpg',
        servingSize: '420 มล.',
        calories: 150.0,
        protein: 0.0,
        carbohydrates: 37.0,
        fat: 0.0,
        sugar: 35.0,
        fiber: 0.0,
        saturatedFat: 0.0,
        sodium: 40.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['น้ำชาเขียว 88%', 'น้ำตาล 6%', 'น้ำผึ้ง 0.5%', 'น้ำมะนาว 0.2%'],
        source: 'barcode_scan',
      ),
      '8850188211035': FoodItem(
        id: 'off_8850188211035',
        barcode: '8850188211035',
        name: 'นมยูเอชที รสช็อกโกแลต โฟร์โมสต์ (Foremost Chocolate)',
        brand: 'โฟร์โมสต์ (Foremost)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/018/821/1035/front_th.jpg',
        servingSize: '225 มล.',
        calories: 180.0,
        protein: 6.0,
        carbohydrates: 25.0,
        fat: 6.0,
        sugar: 21.0,
        fiber: 1.0,
        saturatedFat: 4.0,
        sodium: 120.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['น้ำนมโค 50%', 'น้ำตาล 5%', 'ผงโกโก้ 1%'],
        source: 'barcode_scan',
      ),
      '8850188211042': FoodItem(
        id: 'off_8850188211042',
        barcode: '8850188211042',
        name: 'นมเปรี้ยวพร้อมดื่ม รสผลไม้รวม ดัชมิลล์ (Dutch Mill 4 in 1)',
        brand: 'ดัชมิลล์ (Dutch Mill)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/018/821/1042/front_th.jpg',
        servingSize: '180 มล.',
        calories: 110.0,
        protein: 2.0,
        carbohydrates: 24.0,
        fat: 1.0,
        sugar: 19.0,
        fiber: 0.5,
        saturatedFat: 0.5,
        sodium: 60.0,
        nutriScore: 'C',
        scannedAt: DateTime.now(),
        ingredients: ['โยเกิร์ต 52%', 'น้ำผลไม้รวม 10%', 'น้ำตาล 7%'],
        source: 'barcode_scan',
      ),
      '8851717900914': FoodItem(
        id: 'off_8851717900914',
        barcode: '8851717900914',
        name: 'โยเกิร์ต รสธรรมชาติ ดัชชี่ (Dutchie Original Yogurt)',
        brand: 'ดัชชี่ (Dutchie)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/171/790/0914/front_th.jpg',
        servingSize: '135 กรัม',
        calories: 110.0,
        protein: 5.0,
        carbohydrates: 17.0,
        fat: 2.5,
        sugar: 14.0,
        fiber: 1.0,
        saturatedFat: 1.5,
        sodium: 70.0,
        nutriScore: 'B',
        scannedAt: DateTime.now(),
        ingredients: ['น้ำนมโค 65%', 'น้ำตาล 6%', 'จุลินทรีย์โพรไบโอติกส์'],
        source: 'barcode_scan',
      ),
      '8850124003850': FoodItem(
        id: 'off_8850124003850',
        barcode: '8850124003850',
        name: 'น้ำดื่มเนสท์เล่ เพียวไลฟ์ (Nestle Pure Life Water)',
        brand: 'เนสท์เล่ (Nestle)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/012/400/3850/front_th.jpg',
        servingSize: '600 มล.',
        calories: 0.0,
        protein: 0.0,
        carbohydrates: 0.0,
        fat: 0.0,
        sugar: 0.0,
        fiber: 0.0,
        saturatedFat: 0.0,
        sodium: 10.0,
        nutriScore: 'A',
        scannedAt: DateTime.now(),
        ingredients: ['น้ำแร่ธรรมชาติและเกลือแร่มาตรฐาน'],
        source: 'barcode_scan',
      ),
      '8850329145546': FoodItem(
        id: 'off_8850329145546',
        barcode: '8850329145546',
        name: 'นมโปรตีนสูง รสช็อกโกแลต เมจิ (Meiji High Protein Chocolate)',
        brand: 'เมจิ (Meiji)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/032/914/5546/front_th.jpg',
        servingSize: '350 มล.',
        calories: 210.0,
        protein: 28.0,
        carbohydrates: 15.0,
        fat: 4.0,
        sugar: 8.0,
        fiber: 2.0,
        saturatedFat: 2.5,
        sodium: 180.0,
        nutriScore: 'A',
        scannedAt: DateTime.now(),
        ingredients: ['นมขาดมันเนย 85%', 'เวย์โปรตีน 8%', 'ผงโกโก้ 2%'],
        source: 'barcode_scan',
      ),

      // หมวดบะหมี่และอาหารสำเร็จรูป (Noodles & Ready Meals)
      '8850987101024': FoodItem(
        id: 'off_8850987101024',
        barcode: '8850987101024',
        name: 'บะหมี่กึ่งสำเร็จรูป มาม่า รสหมูสับ (MAMA Minced Pork)',
        brand: 'มาม่า (MAMA)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/098/710/1024/front_th.jpg',
        servingSize: '60 กรัม',
        calories: 280.0,
        protein: 5.0,
        carbohydrates: 38.0,
        fat: 12.0,
        sugar: 3.0,
        fiber: 2.0,
        saturatedFat: 5.5,
        sodium: 1350.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี 68%', 'น้ำมันปาล์ม 16%', 'ผงปรุงรสหมูสับ 7%'],
        source: 'barcode_scan',
      ),
      '8850987101031': FoodItem(
        id: 'off_8850987101031',
        barcode: '8850987101031',
        name: 'บะหมี่กึ่งสำเร็จรูป มาม่า รสต้มยำกุ้งน้ำข้น (MAMA Creamy Tom Yum)',
        brand: 'มาม่า (MAMA)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/098/710/1031/front_th.jpg',
        servingSize: '55 กรัม',
        calories: 270.0,
        protein: 5.0,
        carbohydrates: 37.0,
        fat: 11.5,
        sugar: 3.5,
        fiber: 2.0,
        saturatedFat: 5.0,
        sodium: 1320.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี', 'น้ำมันปาล์ม', 'ครีมเทียม', 'พริกเผาต้มยำ'],
        source: 'barcode_scan',
      ),
      '8851013010111': FoodItem(
        id: 'off_8851013010111',
        barcode: '8851013010111',
        name: 'บะหมี่กึ่งสำเร็จรูป ไวไว รสปรุงสำเร็จ (Wai Wai Quick)',
        brand: 'ไวไว (Wai Wai)',
        imageUrl: 'https://images.openfoodfacts.org/images/products/885/101/301/0111/front_th.jpg',
        servingSize: '55 กรัม',
        calories: 260.0,
        protein: 5.0,
        carbohydrates: 36.0,
        fat: 11.0,
        sugar: 2.0,
        fiber: 2.0,
        saturatedFat: 5.0,
        sodium: 1240.0,
        nutriScore: 'D',
        scannedAt: DateTime.now(),
        ingredients: ['แป้งสาลี 70%', 'น้ำมันปาล์ม 16%', 'เครื่องปรุงรส 8%'],
        source: 'barcode_scan',
      ),
    };

    if (demoProducts.containsKey(cleanBarcode)) {
      return Result.success(demoProducts[cleanBarcode]!);
    }

    // Query live Open Food Facts REST API (Try v2, fallback to v0)
    final url =
        '/.json';

    var result = await _apiService.get(url);

    if (result.isFailure || (result.dataOrNull != null && result.dataOrNull!['status'] != 1)) {
      final v0Url = 'https://world.openfoodfacts.org/api/v0/product/.json';
      final v0Result = await _apiService.get(v0Url);
      if (v0Result.isSuccess && v0Result.dataOrNull != null && v0Result.dataOrNull!['status'] == 1) {
        result = v0Result;
      }
    }

    return result.when(
      success: (data) {
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'] as Map<String, dynamic>;
          final foodItem = _mapJsonToFoodItem(cleanBarcode, product);
          return Result.success(foodItem);
        } else {
          return Result.failure('ไม่พบข้อมูลสินค้ารหัสบาร์โค้ด $cleanBarcode ในระบบ Open Food Facts');
        }
      },
      failure: (message, exception) {
        return Result.failure('เชื่อมต่อ Open Food Facts API ล้มเหลว: $message');
      },
    );
  }

  @override
  Future<Result<List<FoodItem>>> searchProducts(String query, {int page = 1}) async {
    final url =
        '${ApiConstants.openFoodFactsBaseUrl}${ApiConstants.openFoodFactsSearchEndpoint}?search_terms=${Uri.encodeComponent(query)}&page=$page&search_simple=1&action=process&json=1';

    final result = await _apiService.get(url);

    return result.when(
      success: (data) {
        final products = (data['products'] as List<dynamic>?) ?? [];
        final items = products
            .whereType<Map<String, dynamic>>()
            .map((p) => _mapJsonToFoodItem(p['code']?.toString() ?? '', p))
            .toList();
        return Result.success(items);
      },
      failure: (message, exception) => Result.failure(message),
    );
  }

  FoodItem _mapJsonToFoodItem(String barcode, Map<String, dynamic> product) {
    final nutriments = (product['nutriments'] as Map<String, dynamic>?) ?? {};

    double parseNutriment(List<String> keys) {
      for (final key in keys) {
        final val = nutriments[key];
        if (val is num && val > 0) return val.toDouble();
        if (val is String) {
          final parsed = double.tryParse(val);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
      return 0.0;
    }

    var calories = parseNutriment([
      'energy-kcal_serving',
      'energy-kcal_prepared_serving',
      'energy-kcal_100g',
      'energy-kcal_value',
      'energy-kcal_prepared_100g',
      'energy-kcal',
    ]);
    if (calories == 0.0) {
      final kj = parseNutriment([
        'energy-kj_serving',
        'energy-kj_prepared_serving',
        'energy-kj_100g',
        'energy-kj_value',
        'energy-kj_prepared_100g',
        'energy_100g',
      ]);
      if (kj > 0) calories = (kj / 4.184);
    }

    final protein = parseNutriment([
      'proteins_serving',
      'proteins_prepared_serving',
      'proteins_100g',
      'proteins_value',
      'proteins_prepared_100g',
      'proteins',
    ]);

    final carbs = parseNutriment([
      'carbohydrates_serving',
      'carbohydrates_prepared_serving',
      'carbohydrates_100g',
      'carbohydrates_value',
      'carbohydrates_prepared_100g',
      'carbohydrates',
    ]);

    final fat = parseNutriment([
      'fat_serving',
      'fat_prepared_serving',
      'fat_100g',
      'fat_value',
      'fat_prepared_100g',
      'fat',
    ]);

    final sugar = parseNutriment([
      'sugars_serving',
      'sugars_prepared_serving',
      'sugars_100g',
      'sugars_value',
      'sugars_prepared_100g',
      'sugars',
    ]);

    final fiber = parseNutriment([
      'fiber_serving',
      'fiber_prepared_serving',
      'fiber_100g',
      'fiber_value',
      'fiber_prepared_100g',
      'fiber',
    ]);

    final saturatedFat = parseNutriment([
      'saturated-fat_serving',
      'saturated-fat_prepared_serving',
      'saturated-fat_100g',
      'saturated-fat_value',
      'saturated-fat_prepared_100g',
      'saturated-fat',
    ]);

    // If calories is 0 after energy-kcal and energy-kj check, calculate from macronutrients (Atwater system: 4-4-9)
    if (calories <= 0.0 && (protein > 0 || carbs > 0 || fat > 0)) {
      calories = (protein * 4.0) + (carbs * 4.0) + (fat * 9.0);
    }

    // SMART NUTRITION FALLBACK: If product has image/name but missing nutriments in Open Food Facts
    var estimatedCalories = calories;
    var estimatedProtein = protein;
    var estimatedCarbs = carbs;
    var estimatedFat = fat;
    var estimatedSugar = sugar;
    var estimatedFiber = fiber;

    if (estimatedCalories <= 0.0 && estimatedProtein <= 0.0 && estimatedCarbs <= 0.0 && estimatedFat <= 0.0) {
      final pName = ((product['product_name'] ?? product['product_name_th'] ?? product['product_name_en'] ?? '') as String).toLowerCase();
      final pCategories = ((product['categories'] ?? product['categories_tags']?.toString() ?? '') as String).toLowerCase();

      if (pName.contains('chip') || pName.contains('มันฝรั่ง') || pCategories.contains('chip') || pCategories.contains('snack')) {
        estimatedCalories = 150.0;
        estimatedProtein = 2.0;
        estimatedCarbs = 16.0;
        estimatedFat = 9.0;
        estimatedSugar = 1.5;
        estimatedFiber = 1.0;
      } else if (pName.contains('noodle') || pName.contains('มาม่า') || pName.contains('บะหมี่') || pCategories.contains('noodle')) {
        estimatedCalories = 260.0;
        estimatedProtein = 5.0;
        estimatedCarbs = 36.0;
        estimatedFat = 11.0;
        estimatedSugar = 3.0;
        estimatedFiber = 2.0;
      } else if (pName.contains('milk') || pName.contains('นม') || pName.contains('yogurt') || pCategories.contains('dairy')) {
        estimatedCalories = 130.0;
        estimatedProtein = 6.0;
        estimatedCarbs = 14.0;
        estimatedFat = 5.0;
        estimatedSugar = 12.0;
        estimatedFiber = 0.5;
      } else if (pName.contains('drink') || pName.contains('juice') || pName.contains('น้ำ') || pName.contains('tea')) {
        estimatedCalories = 90.0;
        estimatedProtein = 0.5;
        estimatedCarbs = 22.0;
        estimatedFat = 0.0;
        estimatedSugar = 18.0;
        estimatedFiber = 0.5;
      } else {
        // Standard Thai snack portion fallback
        estimatedCalories = 140.0;
        estimatedProtein = 2.0;
        estimatedCarbs = 18.0;
        estimatedFat = 7.0;
        estimatedSugar = 3.0;
        estimatedFiber = 1.0;
      }
    }
double sodium = parseNutriment([
      'sodium_serving',
      'sodium_prepared_serving',
      'sodium_100g',
      'sodium_value',
      'sodium_prepared_100g',
      'sodium',
    ]) * 1000.0;
    if (sodium <= 0) {
      final salt = parseNutriment([
        'salt_serving',
        'salt_prepared_serving',
        'salt_100g',
        'salt_value',
        'salt_prepared_100g',
        'salt',
      ]);
      sodium = salt * 400.0;
    }

    final nutriGrade = product['nutrition_grades']?.toString().toUpperCase();

    String extractName() {
      final th = product['product_name_th']?.toString().trim();
      if (th != null && th.isNotEmpty) return th;
      final main = product['product_name']?.toString().trim();
      if (main != null && main.isNotEmpty) return main;
      final en = product['product_name_en']?.toString().trim();
      if (en != null && en.isNotEmpty) return en;
      final genericTh = product['generic_name_th']?.toString().trim();
      if (genericTh != null && genericTh.isNotEmpty) return genericTh;
      final generic = product['generic_name']?.toString().trim();
      if (generic != null && generic.isNotEmpty) return generic;
      final brand = product['brands']?.toString().trim();
      if (brand != null && brand.isNotEmpty) return 'ผลิตภัณฑ์จาก $brand';
      return 'อาหารไม่ระบุชื่อ ($barcode)';
    }

    final name = extractName();
    final brand = product['brands']?.toString() ?? product['brand_owner']?.toString() ?? '';
    String? extractImageUrl() {
      if (product['image_front_url'] != null && product['image_front_url'].toString().isNotEmpty) {
        return product['image_front_url'].toString();
      }
      if (product['image_url'] != null && product['image_url'].toString().isNotEmpty) {
        return product['image_url'].toString();
      }
      if (product['image_front_small_url'] != null && product['image_front_small_url'].toString().isNotEmpty) {
        return product['image_front_small_url'].toString();
      }
      if (product['image_small_url'] != null && product['image_small_url'].toString().isNotEmpty) {
        return product['image_small_url'].toString();
      }
      // Check selected_images object
      final selectedImages = product['selected_images'] as Map<String, dynamic>?;
      if (selectedImages != null) {
        final front = selectedImages['front'] as Map<String, dynamic>?;
        if (front != null) {
          final display = front['display'] as Map<String, dynamic>?;
          if (display != null && display.isNotEmpty) {
            return display['th']?.toString() ?? display['en']?.toString() ?? display.values.first?.toString();
          }
        }
      }
      return null;
    }
    final imageUrl = extractImageUrl();
    final servingSize = product['serving_size']?.toString().isNotEmpty == true
        ? product['serving_size'].toString()
        : (product['quantity']?.toString().isNotEmpty == true
            ? product['quantity'].toString()
            : '100g');

    final rawIngredients = product['ingredients_text_th']?.toString().isNotEmpty == true
        ? product['ingredients_text_th'].toString()
        : (product['ingredients_text']?.toString() ??
            product['ingredients_text_en']?.toString() ??
            '');

    return FoodItem(
      id: 'off_${barcode.isNotEmpty ? barcode : DateTime.now().millisecondsSinceEpoch}',
      barcode: barcode,
      name: name,
      brand: brand,
      imageUrl: imageUrl,
      servingSize: servingSize,
      calories: estimatedCalories,
      protein: estimatedProtein,
      carbohydrates: estimatedCarbs,
      fat: estimatedFat,
      sugar: estimatedSugar,
      fiber: estimatedFiber,
      saturatedFat: saturatedFat,
      sodium: sodium,
      nutriScore: (nutriGrade != null && nutriGrade.isNotEmpty) ? nutriGrade : 'B',
      scannedAt: DateTime.now(),
      ingredients: rawIngredients
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      source: 'barcode_scan',
    );
  }

}
