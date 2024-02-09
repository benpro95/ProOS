LCDPI_MSG=$1

## Send message to LCDpi
LCD_HOST="lcdpi.home"

## Convert Text (TEXT->JSON->BASE64)
JSONDATA=$(echo "$LCDPI_MSG" | jq -Rsc '. / "\n" - [""]' | base64)
## Send Message
/usr/bin/curl -silent --fail --ipv4 --no-buffer \
   --max-time 5 --retry 2 --no-keepalive \
   -X POST "http://$LCD_HOST/update.php?file=message&action=update" \
   -H "Content-Type", "text/plain" --data "$JSONDATA"
## Display Message
/usr/bin/curl -silent --fail --ipv4 --no-buffer \
   --max-time 5 --retry 2 --no-keepalive \
   --data "var=&arg=message&action=main" "http://$LCD_HOST/exec.php"

exit