# Area6510

### Input-de-Luxe
This is a small utility to add better input methods to BASIC applications.

With Input-de-Luxe (IDL) you can set the position and length of input fields. It is also possible to specify menu shortcuts or colored input fileds.
Have a look at the demo to see what IDL can do for you:

```
load"input-de-luxe",8
run
load"inputdl-demo",8
run
```

#### Usage
Shortest call:

```
sys2093,z,s,l,t$,q$,ek$,vo
```
    z  : Line / Y-position
    s  : Char / X-position
    l  : Length
    t$ : Allowed keys, use :
         CTRL+K -> a-z
         CTRL+G -> A-Z
         CTRL+Z -> 0-9
         CTRL+A -> All chars
    q$ : Target variable
    ek$: Shortcuts
    vo : Add text to input filed
         0   = no text
         1   = use q$ as input
         vo$ = use vo$ as input

It is possible to add additional parameters:
```
sys2093,ze,sp,la,t$,z$,e$,vo[,fm,hm,po,an,fw,fn,rm,cm,ev,cv]
```
    fm : Mark input filed 0/1
    hm : Hide input 0/1
    po : Set cursor position
    an : Required input chars
    fw : Color before input / 255 = keep color at input field
    fn : Color after input
    rm : Reverse mode 0/1
    cm : Multi-color mode 0/1
    ev : Variable for exit code
    cv : Variable for cursor position

If some additional parameters are missing, then previous values will be used.

#### PRINT
You can print text at a specific position:
```
sys2090,z,s,"text"
```
    z     : Line / Y-position
    s     : Char / X-position
    "text": Text to print...

#### Additional features
Documentation need to be updated:
```
sys2096... -> Call IDL using Assembler code
sys2099... -> Re-define chars for input field, hide code
sys2102,0  -> Print help message
sys2102,x  -> Print parameter error
sys2105    -> Change edit keys
```
