Hack Notes
----------

# Custom Script
[DFHack]# reveal-des

Reveals designated tiles, useful for ignoring damp / warm stone cancellations.

# Paint Rough Wall

```
[DFHack]# tiletypes
tiletypes> paint sp normal
tiletypes> paint sh wall
tiletypes> paint m stone granite
tiletypes> run
tiletypes> q
```

Should see something like:

`Paint: NORMAL STONE WALL INORGANIC:GRANITE CLUSTER`

If it worked properly.  Messing up the material is the easiest thing to do.
The material needs to be all lower case.


Work Order Management
---------------------

Dedicated sand collection can be accomplished by creating a glass workshop that
does not accept general work orders (in the workshop profile).  It can then be
given a workorder with conditions on number of items with the sand bearing
trait.  I have not reliably figured out conditions for empty cloth bags.


Uniform Layout
--------------
| Item         | Material | Cost |
| ------------ | -------- | ----:|
| Mail Shirt   | Metal    | 2    |
| Breast Plate | Metal    | 3    |
| Cloak        | Leather  | 1    |
| Helm         | Metal    | 1    |
| Hood         | Leather  | 1    |
| Trousers     | Cloth    | 1    |
| Greaves      | Metal    | 2    |
| Gauntlets    | Metal    | 1    |
| Socks        | Cloth    | 1    |
| High Boots   | Metal    | 1    |
| Shield       | Wood     | 1    |
| Weapon       | Metal    | 1    |
