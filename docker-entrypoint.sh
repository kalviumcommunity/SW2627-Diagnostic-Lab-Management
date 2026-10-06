#!/bin/sh
PORT=${PORT:-8080}

# Update Nginx listen port if PORT environment variable is specified
sed -i "s/listen [0-9]*;/listen ${PORT};/g" /etc/nginx/conf.d/default.conf

echo ""
echo "=========================================================================="
echo "  🔬 LabTrack: Diagnostic Lab Management System"
echo "  🚀 Status: Container is running and ready to accept traffic"
echo ""
echo "  🔗 DIRECT APPLICATION ACCESS LINK:"
echo "     👉 http://localhost:${PORT}"
echo ""
echo "  (Hold Ctrl and Click the link above to open directly in your browser)"
echo "=========================================================================="
echo ""

exec nginx -g "daemon off;"
