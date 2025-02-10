# Node-Red, Flows and components

This folder contains node-red flows. Some of them work in complementary way with Home-Assistant components or are the data source for them.

They import as usual unless stated.

## Brief

### JKBMS USB Decoding

This flows allows communicating with JKBMS physically connected to the node-red machine vía USB Serial converter. This exports a payload in the format accepted by the ([Mqtt battery driver by MrManuel](https://github.com/mr-manuel/venus-os_dbus-mqtt-battery)).
You use this code to integrate JKBMS to remote Victron systems or, as in my case, integrate and process sensors from several JKBMS banks to a big unified battery.

For connection of the device, you can follow the [nice connection how-to at MrManuel repos](https://mr-manuel.github.io/venus-os_dbus-serialbattery_docs/general/connect)

If you connect the JKBMS directly to the VenusGX device, you'll need to make sure that you don't have installed a driver for it, like the one at the last link, or it'll be picked by the driver.

Also you'll need to tell the VenusOs to stop polling the USB port where the JKBMS is connected or the flow won't be able to access it. You have instructions on how to do it [HERE](https://github.com/victronenergy/venus/wiki/howto-add-a-driver-to-Venus#howto-make-serial-starter-ignore-certain-usb-types). Basically you'll need to get the JKBMS USB Id and add it as a exclusion to the file stated.

> [!TIP]
> It will be preferable to use device id's instead of USB addresses (ttyUSB0). They appear in the flow, because I use them for debug purposes.

> [!WARNING]  
> Banning the TTL device model in the serial-starter.rules file can result in banning other USB dongles, as the one used for your meters, as they could share the same model. There's a procedure that involves changing the Model Id with a custom unique string with [the FT_PROG programming tool](https://ftdichip.com/utilities/) but I leave it at your own risk.
