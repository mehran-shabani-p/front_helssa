import 'package:flutter/material.dart';

class SpecialVisitColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFFF1F8E9);
}

final List<Map<String, dynamic>> guidelines = [
  {
    'title': 'علائم خطرناک سردرد',
    'content': 'سردرد شدید ناگهانی، تب بالا، تاری دید، تهوع و استفراغ نیاز به مراجعه فوری دارد.',
    'icon': Icons.warning_amber_rounded,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'تفاوت انفولانزا و سرماخوردگی',
    'content': 'انفولانزا: تب بالا، درد عضلات، خستگی شدید\nسرماخوردگی: آبریزش بینی، گلودرد خفیف',
    'icon': Icons.coronavirus,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'انواع اسهال',
    'content': 'عفونی: همراه تب و درد\nمسافرتی: بدون تب\nناشی از گرما: کم‌آبی بدن',
    'icon': Icons.water_drop,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'بیماری‌های شایع فصلی',
    'content': 'زمستان: سرماخوردگی، آنفولانزا\nتابستان: مسمومیت غذایی، آفتاب‌سوختگی',
    'icon': Icons.calendar_today,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'علائم کم‌آبی بدن',
    'content': 'خشکی دهان، ادرار تیره، سرگیجه\nنیاز به مصرف مایعات و محلول الکترولیت',
    'icon': Icons.local_drink,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'پیشگیری از فشار خون بالا',
    'content': 'کاهش نمک، ورزش منظم، کنترل وزن',
    'icon': Icons.monitor_heart,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'کنترل قند خون در دیابت',
    'content': 'رژیم کم‌قند، فعالیت بدنی، اندازه‌گیری منظم گلوکز',
    'icon': Icons.bloodtype,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'مدیریت آلرژی فصلی',
    'content': 'اجتناب از گرده، مصرف آنتی‌هیستامین، ماسک در فضای باز',
    'icon': Icons.grass,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'سوختگی سطحی',
    'content': 'خنک‌کردن سریع، پوشاندن با گاز تمیز، عدم استفاده از خمیردندان',
    'icon': Icons.local_fire_department,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'مسمومیت غذایی',
    'content': 'تهوع، اسهال، درد شکم\nمصرف مایعات و مراجعه در صورت شدید بودن',
    'icon': Icons.lunch_dining,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'بهداشت خواب',
    'content': 'خاموشی وسایل الکترونیک، اتاق تاریک، زمان ثابت خواب',
    'icon': Icons.bedtime,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'ورم پاها',
    'content': 'بالا نگه‌داشتن پا، جوراب فشاری، بررسی نارسایی قلبی',
    'icon': Icons.accessibility,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'سلامت دهان و دندان',
    'content': 'مسواک دوبار در روز، نخ دندان، معاینه شش ماهه',
    'icon': Icons.medical_services,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'تغذیه سالم کودک',
    'content': 'شیر مادر، میوه و سبزی، محدودیت قند',
    'icon': Icons.child_care,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'اهمیت واکسیناسیون',
    'content': 'پیشگیری از بیماری‌های عفونی، تقویم واکسن را رعایت کنید',
    'icon': Icons.vaccines,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'ورزش در سالمندان',
    'content': 'پیاده‌روی، تمرین تعادل، اجتناب از حرکات پرخطر',
    'icon': Icons.emoji_people,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'مدیریت استرس',
    'content': 'تنفس عمیق، مدیتیشن، مشاوره در صورت نیاز',
    'icon': Icons.self_improvement,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'درد قفسه سینه (آنژین)',
    'content': 'درد فشاری، انتشار به دست چپ\nنیاز به ارزیابی فوری',
    'icon': Icons.favorite,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'علائم سکته مغزی',
    'content': 'افتادگی صورت، ضعف دست، اختلال گفتار\nتماس فوری با اورژانس',
    'icon': Icons.emergency,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'کمردرد حاد',
    'content': 'استراحت کوتاه، حرکات کششی، مراجعه در صورت درد پایدار',
    'icon': Icons.airline_seat_recline_extra,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'استفاده صحیح از اسپری بینی',
    'content': 'سر را کمی به جلو، اسپری به دیواره خارجی بینی، عدم استنشاق عمیق',
    'icon': Icons.air,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'زخم معده',
    'content': 'درد شکم، سوزش\nاجتناب از NSAID، مصرف مهارکننده پمپ پروتون',
    'icon': Icons.medical_information,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'استئوآرتریت زانو',
    'content': 'درد با فعالیت، خشکی صبحگاهی کوتاه، کاهش وزن',
    'icon': Icons.directions_walk,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'دیابت بارداری',
    'content': 'غربالگری هفته ۲۴-۲۸، رژیم غذایی، کنترل قند',
    'icon': Icons.pregnant_woman,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'عفونت ادراری',
    'content': 'سوزش، تکرر ادرار، بوی بد\nنیاز به آزمایش و آنتی‌بیوتیک',
    'icon': Icons.water_drop,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'تغذیه دوران بارداری',
    'content': 'اسیدفولیک، آهن، اجتناب از غذاهای خام',
    'icon': Icons.rice_bowl,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'پیشگیری از سرطان پوست',
    'content': 'کرم ضدآفتاب SPF30، لباس پوشیده، اجتناب از آفتاب ظهر',
    'icon': Icons.wb_sunny,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'سرگیجه و بی‌هوشی',
    'content': 'نشستن سریع، نوشیدن آب، مراجعه در صورت تکرار',
    'icon': Icons.sync_problem,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'تنظیم دمای بدن نوزاد',
    'content': 'استفاده از لباس لایه‌ای، پرهیز از گرم‌کردن بیش از حد',
    'icon': Icons.thermostat,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'عوارض آنتی‌بیوتیک',
    'content': 'اسهال، راش پوستی، مقاومت باکتریایی\nمصرف فقط با تجویز پزشک',
    'icon': Icons.healing,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'بیماری‌های مشترک انسان و حیوان',
    'content': 'هاری، تب مالت، سالمونلا\nواکسیناسیون و رعایت بهداشت',
    'icon': Icons.pets,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'اختلال نقص توجه در بزرگسالان',
    'content': 'حواس‌پرتی، بی‌قراری، مدیریت زمان\nدرمان دارویی و رفتاری',
    'icon': Icons.school,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'عوارض مصرف الکل',
    'content': 'بیماری کبد، فشارخون، اعتیاد\nمصرف مسئولانه یا ترک',
    'icon': Icons.local_bar,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'پیشگیری از چاقی کودکان',
    'content': 'فعالیت بدنی، حذف نوشابه، الگوی غذایی خانواده',
    'icon': Icons.fastfood,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'سفر ایمن در بارداری',
    'content': 'کمربند روی لگن، توقف هر ۲ ساعت، مصرف مایعات',
    'icon': Icons.airplanemode_active,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'درمان خانگی سوختگی خفیف',
    'content': 'شستشو با آب سرد، پانسمان استریل، عدم ترکاندن تاول',
    'icon': Icons.spa,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'پیشگیری از سنگ کلیه',
    'content': 'نوشیدن ۲ لیتر آب، کاهش نمک، مصرف مرکبات',
    'icon': Icons.kitchen,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'تغذیه ورزشکاران',
    'content': 'کربوهیدرات قبل از ورزش، پروتئین پس از تمرین، هیدراتاسیون',
    'icon': Icons.fitness_center,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'سلامت روان نوجوانان',
    'content': 'گفت‌وگوی باز، تشویق به فعالیت اجتماعی، مراجعه به مشاور',
    'icon': Icons.psychology,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'واکسن HPV',
    'content': 'پیشگیری از سرطان دهانه رحم، سن توصیه: ۹-۱۴ سال',
    'icon': Icons.vaccines,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'تشنج در کودکان',
    'content': 'حفظ ایمنی محیط، عدم قراردادن شیء در دهان، تماس با اورژانس',
    'icon': Icons.warning_amber_rounded,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'کم‌خونی',
    'content': 'خستگی، رنگ‌پریدگی، تنگی نفس\nآهن و ویتامین B12 کافی',
    'icon': Icons.opacity,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'پیشگیری از COVID-19',
    'content': 'واکسن، ماسک، تهویه مناسب',
    'icon': Icons.health_and_safety,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'کنترل فشار چشم',
    'content': 'معاینه سالانه، قطره تجویز شده، عدم قطع ناگهانی دارو',
    'icon': Icons.remove_red_eye,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'پیشگیری از سقوط سالمندان',
    'content': 'نصب دستگیره، کفش مناسب, روشنایی کافی',
    'icon': Icons.elderly,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'اختلالات تیروئید',
    'content': 'تغییر وزن، ضربان قلب نامنظم، آزمایش TSH',
    'icon': Icons.science,
    'color': SpecialVisitColors.lightGreen,
  },
  {
    'title': 'مدیریت درد مزمن',
    'content': 'ورزش سبک، فیزیوتراپی، داروهای غیرمخدر',
    'icon': Icons.sick,
    'color': SpecialVisitColors.darkGreen,
  },
  {
    'title': 'مراقبت از پوست خشک',
    'content': 'کرم مرطوب‌کننده، دوش کوتاه، صابون ملایم',
    'icon': Icons.face_retouching_natural,
    'color': SpecialVisitColors.softGreen,
  },
  {
    'title': 'پیشگیری از کم‌تحرکی',
    'content': 'استراحت فعال هر ۳۰ دقیقه، استفاده از پله، قدم‌شمار',
    'icon': Icons.directions_run,
    'color': SpecialVisitColors.primaryGreen,
  },
  {
    'title': 'ایمنی غذای خیابانی',
    'content': 'انتخاب فروشنده تمیز, غذای داغ, شستن دست‌ها',
    'icon': Icons.restaurant,
    'color': SpecialVisitColors.lightGreen,
  },
];
