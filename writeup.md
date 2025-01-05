competing standards
-------------------

User gets a big binary file and a pdf with a VM specification they
need to implement.
After running the binary file with VM written by them, it

* does sanity checks to make sure it was implemented correctly,
* asks the user some questions about SFI and one project euler question (the answer for every one can be read from the stack),
* spits out JPEG binary with the flag.

example solution:

```c
#include <stdio.h>
#include <stdint.h>
#include <err.h>

#define $(a,b) case(a):{b; break;}
#define N(a,b) $(a, b; ip++)
#define B(n,o) $(n, S[s-2]=S[s-1] o S[s-2]; s--; ip++)
#define I int32_t
#define U uint8_t

I ip, s, c, S[1<<16], C[1<<16], d;
U D[1<<16];

int
main(void)
{
  d=fread(D, 1, 1<<16, fopen("flag.bin", "r")), ip=s=c=0;

  while (ip < d) {
    switch (D[ip]) {
      $(0, S[s++]=(D[ip+4]<<24)|(D[ip+3]<<16)|(D[ip+2]<<8)|D[ip+1]; ip += 5);
      N(1, s--);
      N(3, I t=S[s-1]; S[s-1]=S[s-2]; S[s-2]=t);
      B(4, -);
      B(5, +);
      B(6, *);
      B(7, /);
      B(8, ^);
      B(9, <<);
      B(10, >>);
      N(11, putchar(S[--s]); fflush(stdout));
      $(12, S[s++]=getchar(); ip++);
      $(13, I a=S[--s];I b=S[--s];I c=S[--s]; ip=b==c?a:ip+1; S[s++]=c; S[s++]=b);
      $(14, I a=S[--s];I b=S[--s];I c=S[--s]; ip=b!=c?a:ip+1; S[s++]=c; S[s++]=b);
      $(15, I a=S[--s];I b=S[--s]; ip=b<0?a:ip+1; S[s++]=b);
      $(16, I a=S[--s];C[c++]=ip+1; ip=a);
      $(17, ip = S[--s]);
      $(18, ip = C[--c]);
      N(19, S[s]=S[s-1]; s++);
      $(20, I a=S[--s]; ip=!s?a:ip+1);
      $(21, I a=S[--s]; ip=s?a:ip+1);
      N(22, I a=S[--s]; I b=S[--s]; D[b]=(U)a%256);
      N(23, I a=S[--s]; S[s++]=D[a]);
      N(24, s--); /* ignore CTF stack */
    default:
      errx(1, "unknown op %d", D[ip]);
    }
  }

  return 0;
}
```

assuming this vm is saved as `vm.c`, to see the solution user could use shell pipes:

```sh
$ printf '2005\nyes\n6\n21124\nno\n' | tcc -run vm.c | tail -c +729 > /tmp/a.jpg && sxiv /tmp/a.jpg
# simulate writing answers             to the vm       skip questions               view result
```

the CTF stack even yields a hint mentioning pipes
