#!/usr/bin/env bash
# idempotent_sinov.sh — bir xil kalit bilan 5 marta soʻrov yuboradi (topshiriq 3).
API=${API:-http://localhost:8000}
soni() { curl -s $API/buyurtmalar | python3 -c "import json,sys;print(json.load(sys.stdin)['jami'])"; }

AVVAL=$(soni)
KALIT="k5-$(date +%s%N)"
echo "Kalit: $KALIT"
for i in 1 2 3 4 5; do
  KOD=$(curl -s -o /tmp/t.json -w "%{http_code}" -X POST $API/buyurtmalar \
        -H "Idempotency-Key: $KALIT" -H 'Content-Type: application/json' \
        -d '{"talaba_id":"5001","summa":450000}')
  ID=$(python3 -c "import json;print(json.load(open('/tmp/t.json'))['id'][:8])")
  echo "  $i-soʻrov -> HTTP $KOD, id=$ID"
done
KEYIN=$(soni)
echo
echo "Bazadagi yozuvlar: avval=$AVVAL, keyin=$KEYIN, yangi yozuv=$((KEYIN-AVVAL))"
echo "Kutilgan natija: 5 ta soʻrov, 1 ta yozuv."
