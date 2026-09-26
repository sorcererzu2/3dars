#!/usr/bin/env bash
# sinov.sh — barcha holat kodlarini ketma-ket sinaydi.
# Ishlatilishi:  bash sinov.sh
API=${API:-http://localhost:8000}

kod() { curl -s -o /tmp/tana.json -w "%{http_code}" "$@"; }
# Oʻzbekcha apostrof koʻp baytli boʻlgani uchun printf %-46s notoʻgʻri tekislaydi.
# Shuning uchun boʻsh joy belgilar soni boʻyicha hisoblanadi.
kur() { local n=$(( 46 - ${#1} )); (( n < 1 )) && n=1; printf '%s%*s-> %s\n' "$1" "$n" "" "$2"; }

echo "=== Muvaffaqiyatli holatlar ==================================="
K=$(kod -X POST $API/buyurtmalar -H 'Content-Type: application/json' \
      -d '{"talaba_id":"2001","summa":150000}')
ID=$(python3 -c "import json;print(json.load(open('/tmp/tana.json'))['id'])")
kur "POST /buyurtmalar (yangi)" "$K  (201 kutilgan)"

K=$(kod $API/buyurtmalar/$ID);            kur "GET /buyurtmalar/{id}" "$K  (200 kutilgan)"
K=$(kod "$API/buyurtmalar?sahifa=1&limit=5"); kur "GET /buyurtmalar?sahifa=1&limit=5" "$K  (200 kutilgan)"
K=$(kod -X PATCH $API/buyurtmalar/$ID -H 'Content-Type: application/json' \
      -d '{"holat":"tolandi"}');          kur "PATCH holat: yaratildi -> tolandi" "$K  (200 kutilgan)"

echo
echo "=== Idempotentlik ============================================="
# Kalit har safar yangi boʻlishi kerak: API avvalgi ishdagi kalitni eslab qoladi
KALIT="k-$(date +%s%N)"
K=$(kod -X POST $API/buyurtmalar -H "Idempotency-Key: $KALIT" \
      -H 'Content-Type: application/json' -d '{"talaba_id":"2002","summa":300000}')
kur "POST idempotentlik kaliti (1-marta)" "$K  (201 kutilgan)"
K=$(kod -X POST $API/buyurtmalar -H "Idempotency-Key: $KALIT" \
      -H 'Content-Type: application/json' -d '{"talaba_id":"2002","summa":300000}')
kur "POST ayni kalit (2-marta, ayni tana)" "$K  (200 kutilgan)"
K=$(kod -X POST $API/buyurtmalar -H "Idempotency-Key: $KALIT" \
      -H 'Content-Type: application/json' -d '{"talaba_id":"9999","summa":1}')
kur "POST ayni kalit (boshqa tana)" "$K  (409 kutilgan)"

echo
echo "=== Xatolik holatlari ========================================="
K=$(kod $API/buyurtmalar/yoq-bunday-id);  kur "GET mavjud boʻlmagan id" "$K  (404 kutilgan)"
K=$(kod -X POST $API/buyurtmalar -H 'Content-Type: application/json' \
      -d '{"talaba_id":"3001","summa":-5}'); kur "POST manfiy summa" "$K  (400 kutilgan)"
K=$(kod -X POST $API/buyurtmalar -H 'Content-Type: application/json' \
      -d '{"summa":100}');                kur "POST talaba_id yoʻq" "$K  (400 kutilgan)"
K=$(kod -X PATCH $API/buyurtmalar/$ID -H 'Content-Type: application/json' \
      -d '{"holat":"yaratildi"}');        kur "PATCH tolandi -> yaratildi (orqaga)" "$K  (409 kutilgan)"
K=$(kod -X DELETE $API/buyurtmalar/$ID);  kur "DELETE mavjud buyurtma" "$K  (204 kutilgan)"
K=$(kod -X DELETE $API/buyurtmalar/$ID);  kur "DELETE oʻchirilgan buyurtma" "$K  (404 kutilgan)"

echo
echo "=== Problem Details namunasi =================================="
curl -s -X PATCH $API/buyurtmalar/yoq -H 'Content-Type: application/json' \
     -d '{"holat":"tolandi"}' | python3 -m json.tool
