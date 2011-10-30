extern int clienttotranslatecached;

cell_t W3ExtShowShop2(IPluginContext *pCtx, const cell_t *params);


class Shopmenu2Handler: public IMenuHandler
{
	/*void OnMenuSelect2(IBaseMenu *menu,
		int client,
		unsigned int item,
		unsigned int item_on_page);
*/
	//only need to destroy on end
	void OnMenuEnd(IBaseMenu *menu, MenuEndReason reason);
};

