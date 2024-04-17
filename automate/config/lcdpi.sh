LCDPI_MSG=$1

## Send message to LCDpi
LCD_HOST="lcdpi.home"

## Convert Text to JSON 
JSONDATA=$(echo "$LCDPI_MSG" | jq -Rsc '. / "\n" - [""]')
## Send Message
/usr/bin/curl -silent --fail --ipv4 \
   --max-time 5 --retry 1 --no-keepalive \
   -X POST "http://$LCD_HOST/exec.php?var=&arg=message&action=update" \
   -H "Content-Type", "text/plain" --data "$JSONDATA"
## Display Message
/usr/bin/curl -silent --fail --ipv4 \
   --max-time 5 --retry 1 --no-keepalive \
   --data "var=&arg=message&action=main" "http://$LCD_HOST/exec.php"

exit