# Enphase Gateway Notes

To access the admin console, enable AP mode by pressing (not holding) the 
AP button (second button on the left next to the Cloud Connection button).

Connection to the unsecured WiFi network it broadcasts the SSID is like
ENVOY_<NNNNNN>

There is an administration console for the gateway that's accessible at
https://172.30.1.1/admin/lib/wireless_display

It's easier to access from a laptop versus a phone due to the self signed
SSL certificate.

Can reset the Wifi and do other admin things from here.  Note that

https://172.30.1.1 will just return "Not Found", the webserver does not
seem to be configured to redirect from here to the UI.
