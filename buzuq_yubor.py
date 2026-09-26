# buzuq_yubor.py — atayin buzilgan xabar yuboradi (DLQ ni sinash uchun).
# Xabar API orqali emas, toʻgʻridan toʻgʻri brokerga yuboriladi —
# chunki API bunday xabarni hech qachon yaratmaydi.
import pika

from broker import EXCHANGE, sxemani_yarat, ulanish

ul = ulanish()
kn = ul.channel()
sxemani_yarat(kn)

# 1) JSON emas — isteʼmolchi uni umuman oʻqiy olmaydi
kn.basic_publish(EXCHANGE, "buyurtma.yaratildi", b"{bu JSON emas!!!",
                 pika.BasicProperties(delivery_mode=2))
print("1) sintaktik buzuq xabar yuborildi")

# 2) JSON, lekin mantiqan buzuq — isteʼmolchi ishlov berishda xatoga uchraydi
kn.basic_publish(EXCHANGE, "buyurtma.yaratildi",
                 b'{"id": "buzuq-001", "summa": -5, "buzuq": true}',
                 pika.BasicProperties(delivery_mode=2))
print("2) mantiqan buzuq xabar yuborildi")

ul.close()
print("\nIkkalasi ham DLQ ga tushishi kerak. Tekshirish:")
print("  python navbat_kuzat.py --bir-marta")
