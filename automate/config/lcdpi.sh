## LCDpi Proxy API
## by Ben Provenzano III

RAWMSG=$1

## Send message to LCDpi
LCD_HOST="lcdpi.home"

if [ "$RAWMSG" == "!erase@" ]; then
  ## Clear Message
  /usr/bin/curl -silent --fail --ipv4 \
   --max-time 5 --retry 1 --no-keepalive \
   --data "var=&arg=erase&action=main" "http://$LCD_HOST/exec.php"
  exit
fi

## Convert tildas to space
CONV_MSG=$(echo "$RAWMSG" | sed 's/~/ /g')

## Convert to JSON 
JSONDATA=$(echo "$CONV_MSG" | jq -Rsc '. / "\n" - [""]')

## Send Message
/usr/bin/curl -silent --fail --ipv4 \
   --max-time 5 --retry 2 --no-keepalive \
   -X POST "http://$LCD_HOST/exec.php?var=&arg=message&action=update" \
   -H "Content-Type", "text/plain" --data "$JSONDATA"
   
## Display Message
/usr/bin/curl -silent --fail --ipv4 \
   --max-time 5 --retry 2 --no-keepalive \
   --data "var=&arg=message&action=main" "http://$LCD_HOST/exec.php"

exit

