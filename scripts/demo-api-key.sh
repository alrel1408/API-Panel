#!/bin/bash

# Demo script untuk menunjukkan fitur API Key Management

echo "🚀 AlrelShop API Panel - API Key Management Demo"
echo "================================================"

echo ""
echo "📋 Langkah-langkah menggunakan API Key Management:"

echo ""
echo "1️⃣  GENERATE API KEY BARU (One-Command):"
echo "   sudo /etc/API-Panel/scripts/api-key-manager.sh generate"
echo ""

echo "2️⃣  ATAU menggunakan Interactive Menu:"
echo "   sudo /etc/API-Panel/scripts/api-key-manager.sh"
echo ""

echo "3️⃣  ATAU via API Endpoint:"
echo "   curl -X POST http://localhost:5000/api/admin/generate-api-key \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -H \"X-API-Key: CURRENT_API_KEY\" \\"
echo "     -d '{\"confirm\": true}'"
echo ""

echo "4️⃣  VALIDASI semua file tersync:"
echo "   sudo /etc/API-Panel/scripts/api-key-manager.sh validate"
echo ""

echo "5️⃣  CEK current API key:"
echo "   sudo /etc/API-Panel/scripts/api-key-manager.sh current"
echo ""

echo "6️⃣  TEST API dengan key baru:"
echo "   sudo /etc/API-Panel/scripts/api-key-manager.sh test"
echo ""

echo "✅ Auto-Sync Files:"
echo "   • config/api_config.json"
echo "   • postman_collection.json"
echo "   • scripts/test_api.py"
echo "   • README.md"
echo "   • API_AUTHENTICATION.md"

echo ""
echo "🎉 Manfaat:"
echo "   ✅ Generate secure API key otomatis"
echo "   ✅ Sync ke semua file sekaligus"
echo "   ✅ Backup otomatis sebelum perubahan"
echo "   ✅ Validasi sinkronisasi"
echo "   ✅ Testing langsung"
echo "   ✅ Tidak perlu edit manual!"

echo ""
echo "🚀 Coba sekarang:"
echo "   sudo /etc/API-Panel/scripts/api-key-manager.sh"
