bool GetOwnsItem(cell_t client,cell_t itemid);
void SetOwnsItem(cell_t client,cell_t itemid,bool newownsitem);
cell_t GetClientItemsOwned(cell_t client);
cell_t GetDiamonds(cell_t client);
void SetDiamonds(cell_t client,cell_t count);
#define ITEMS2CANHAVE 3
