# Programming Games for Atari 2600
*by Oscar Toledo G.*
*https://nanochess.org/*

All of the source code from my book *Programming Games for Atari 2600*.

There is a bonus program here *palette.asm* that displays the Atari 2600 palette, and a file *atari_palette.png* containing a reference of colors because the book is black and white.

### ERRATA FOR THE BOOK:

Page 15, it should say 36 to 61, instead of 37 to 62.

Page 98, missing a STA WSYNC just before LDA #2 at the top of page, and it should say LDA #42, instead of LDA #43. The timing is still correct with the errata, but the corrections prevent a bug on certain TV sets. _Discovered by @MechPala (Twitter)_

Page 124, after the source code line _JMP M7_ there should be another line _M16:_ in order to define the label M16 to exit the loop. _Discovered by @MechPala (Twitter)_

Page 164-165, for the assembly code lines saying _STA ENAM0_  the comment should read "Enable/Disable Missile 0". _Discovered by @MechPala (Twitter)_

Page 245, the comment saying "Zero for PF1" should be "Zero for PF2". _Discovered by @MechPala (Twitter)_

Section 9.2 numbering is repeated but this doesn't affect the text, except if you are looking for the other section 9.2. _Discovered by @MechPala (Twitter)_

### NOTES:

These games are fully commented in my new book *Programming Games for Atari 2600*, including a crash course on 6507 programming!

Now available from Lulu and Amazon:

- Soft-cover: https://www.lulu.com/shop/oscar-toledo-gutierrez/programming-games-for-atari-2600/paperback/product-pq9dg4.html
- Hard-cover: https://www.lulu.com/shop/oscar-toledo-gutierrez/programming-games-for-atari-2600/hardcover/product-n8z9r6.html
- Amazon: https://www.amazon.com/dp/1387809962
- eBook: https://nanochess.org/store.html

These are some of the example games documented profusely in the book:

- Game of Ball.
- Wall Breaker.
- Invaders.
- The Lost Kingdom.
- Diamond Craze.
