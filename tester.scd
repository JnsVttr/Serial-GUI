

// works:
// pins
i.tangibleDevices[1][\port].putAll("11111010!");
// wheel
i.tangibleDevices[0][\port].putAll("/wheel/startPos, 100, 0, 400, 2000");  // (command, position, revolution, fade in, speed)
// fader
// six numbers, all without comma or space
// add 0 to numbers below 10 (arduino calculation)
// add '!' at the end to define message ending
i.tangibleDevices[2][\port].putAll("007645014763!");

i.tangibleDevices[1][\name]
i.tangibleDevices[1][\port].put(0)
i.tangibleDevices[1][\port].put(49)
i.tangibleDevices[1][\port].put(33)
i.tangibleDevices[1][\port].put(100)

'1'.ascii // 49
'0'.ascii // 48
"!".ascii // 33
'\n'.ascii // 100








"/dev/tty.SLAB_USBtoUART".split($.);
"/dev/tty.SLAB_USBtoUART".split($.)[1];
"/dev/tty.SLAB_USBtoUART".split($.)[1].beginsWith("SLAB");

"/dev/tty.SLAB_USBtoUART".split($/)[2];
"/dev/tty.SLAB_USBtoUART".split($/)[2].split($.)[0] == "tty";

"/wheel/touchRelease, 1, 0, 0".split($,)
"/wheel/touchRelease, 1, 0, 0".split($,)

"/wheel/touchRelease".split($/)
"/pin".split($/)[1]

"/wheel/touchRelease".split($/)[1]

"/pin 0 1 1 0 1 0 0 0".split($ )
"/wheel/touchRelease, 1, 0, 0".split($ )

"/wheel/touchRelease, 1, 0, 0".replace(",", "").split($ )


~test = 0;
~test = ~test + 1


l = [nil]
l[0] = ();
l[0].put(\port, "slab")
l[0][\port]

l[0] = ('port': "slab");
l[0];


h = "a";
h = h + "s"



h = [1,2,3,4];
h.removeAt(0)
h

i.volumeMap = ControlSpec.new(0, 126, \lin);  // CC 0-126
i.volumeMap.unmap(300)

425 * 0.296
425/126
126/425
126 * 3


90.034.asInteger



-15.thresh(0)
15.min(2)

~tolerance = 2;
~store = 4;
~val = 5;
~store.min(~tolerance)
if ()


((0..10) / 5).collect { |num| [num, num.softRound(1, 0, 1)] };
((0..10) / 5).collect { |num| [num, num.softRound(1, 0.3, 1)] };
((0..10) / 5).collect { |num| [num, num.softRound(1, 0, 0.5)] };


((-10..10)).collect { |num| num = num.thresh(0); [num, num.softRound(3, 0, 1)] };


1.asInteger.thresh(0).softRound(5, 0, 1);



i.mapHighFreq = ControlSpec(30, 60, \lin);
i.mapHighFreq.map(0.9).asInteger;







