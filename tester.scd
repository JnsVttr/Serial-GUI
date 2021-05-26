




128%2
0.6 % 0.1
120%20
320%20
20%10

520%20

0.52359837598253.round(0.01)

126 / 126
12.map

p = "pin";
if ((p=="pin") || (p=="wheel") || (p=="string"), {"yes.postln"})


u = [0]
u.size > 1
0.9.rand

i.sendSerial( ('device': "string", 'content': [0,10,10,10,30,0]) );

l = "pin"
if ((l == "pin") || (l == "wheel") || (l=="string"), {(l).postln;});

// wheel
i.tangibleDevices[0][\inProgress]=true; i.tangibleDevices[0][\port].putAll("1, 300,0,30, 4000");

3.do({|c| i.tangibleDevices[c][\serial].postln  });

3.do({|c| i.tangibleDevices[c][\port].putAll("xxx");  });

3.do({|c| i.tangibleDevices[c][\port].putAll("9");  });

// ID ?
i.tangibleDevices[0][\port].putAll("!");
i.tangibleDevices[0][\port].putAll("9");
i.tangibleDevices[0][\port].putAll("0,50,50,50,50,30,80!");
// works:
// pins
i.tangibleDevices[0][\port].putAll("11111010!");
i.tangibleDevices[0][\port].putAll("10011010!");
i.tangibleDevices[0][\port].putAll("00000000!");
i.tangibleDevices[0][\port].putAll("1");
i.tangibleDevices[0][\port].putAll("!");
i.tangibleDevices[0][\port].put(33); // put byte
i.tangibleDevices[0][\port].put(33); // put byte
// wheel
i.tangibleDevices[1][\port].putAll("/wheel/startPos, 100, 0, 400, 2000");  // (command, position, revolution, fade in, speed)
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
"s".ascii
"9".ascii



i.tangibleDevices.do({|e, c| if (e[\name]=="fader", {e.postln})})



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
126 * 3.37

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



send to Serial Fader:  007935574180!



r = Routine({2.wait;"value".postln;})
r.play


(5 + 5)/2
(5 + 6)/2
(1005 + 1006)/2

if (6 > (5+3), {1.postln}, (0.postln))



w= Array.fill(7, 0);










