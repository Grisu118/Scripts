Scripts
=======

My own Scripts for LWS2013

### Actually this scripts are existing:

Fire Departement:
* [FW_Additional.lua](#FWAdditional)  
* [waterCannon.lua](#WaterCannon)
* [pump.lua](#pump)

Misc
* [AddMoney.lua](#AddMoney)
* [weight_cabel.lua](#weightcabel)

-------

<a name="FWAdditional">
### FW_Additional.lua

This script is an addition for Fire Department Modifications.

With V0.9 it is possible to make the crew (exclude the driver) not visible when nobody is driving the car. Without this Script it is only possible to have a Crew allways inside or when you are in Indoor-Cam the driver is visible.

V1.0 would be also a drl Script inside. 

-------

<a name="WaterCannon">
### waterCannon.lua

not finished yet

-------

<a name="pump">
### pump.lua

not finished yet

-------

<a name="AddMoney">
### AddMoney.lua

This script can add an amount of money hourly to the players account.
The amount is depending to the difficult level of the savegame. 

To use it, you have to add the follow parameter to the vehicle.xml: `<incomePerHour>value</incomePerHour>`

-------

<a name="weightcabel">
### weight_cabel.lua

This script make a mesh visible and an other mesh unvisible when attaching the implement, and when deattaching it do the same, but it's inverse.

##### Paramter:
`<cabel_deattached index="xx" />` The mesh which must be visible when deattached  
`<cabel_attached index="xx" />` The mesh which must be visible when attached
