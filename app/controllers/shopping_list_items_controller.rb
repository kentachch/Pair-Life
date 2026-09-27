class ShoppingListItemsController < ApplicationController
  before_action :require_household
  before_action :set_shopping_list
  before_action :set_item, only: [ :edit, :update, :destroy, :toggle_purchased ]

  def index
    @item = @shopping_list.items.build
    set_items
  end

  def create
    # 追加した人は、フォームからではなくログイン中のユーザーにする
    @item = @shopping_list.items.build(item_params.merge(added_by: current_user))

    if @item.save
      redirect_to shopping_list_items_path, notice: "「#{@item.name}」を追加しました。"
    else
      # 一覧画面をエラー付きで表示し直すので、一覧用のデータも用意する
      set_items
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to shopping_list_items_path, notice: "「#{@item.name}」を変更しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    redirect_to shopping_list_items_path, notice: "「#{@item.name}」を削除しました。", status: :see_other
  end

  def toggle_purchased
    @item.toggle_purchased!
    redirect_to shopping_list_items_path, status: :see_other
  end

  def clear_purchased
    @shopping_list.clear_purchased!
    redirect_to shopping_list_items_path, notice: "チェック済みの物を削除しました。", status: :see_other
  end

  private

  def set_shopping_list
    @shopping_list = current_user.household.shopping_list!
  end

  # 自分の世帯のリストから探すので、他の世帯のアイテムは 404 になる
  def set_item
    @item = @shopping_list.items.find(params[:id])
  end

  # 一覧に表示するデータ。DB から取り直すので、フォーム用に build した未保存のアイテムは含まれない
  def set_items
    @items_by_category = @shopping_list.items_by_category
    @has_purchased = @shopping_list.items.exists?(purchased: true)
  end

  # purchased と added_by は、フォームから変更させない
  def item_params
    params.require(:shopping_list_item).permit(:name, :quantity, :memo, :category, :is_essential)
  end
end
