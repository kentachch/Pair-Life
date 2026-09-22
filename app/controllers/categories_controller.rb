class CategoriesController < ApplicationController
  before_action :require_household
  before_action :set_category, only: [ :edit, :update, :destroy ]

  def index
    @categories = current_user.household.categories.order(:created_at)
    # カテゴリごとの支出の件数 → { カテゴリのID => 件数 }。支出があるカテゴリは削除できないことを画面に示す
    @expense_counts = current_user.household.expenses.group(:category_id).count
  end

  def new
    @category = current_user.household.categories.build
  end

  def create
    # 世帯を経由して作ることで、必ず自分の世帯のカテゴリになる
    @category = current_user.household.categories.build(category_params)

    if @category.save
      redirect_to categories_path, notice: "新しいカテゴリを追加しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: "カテゴリを変更しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 支出が登録されているカテゴリは削除できない(restrict_with_error で false が返る)
    if @category.destroy
      redirect_to categories_path, notice: "カテゴリを削除しました。", status: :see_other
    else
      redirect_to categories_path, alert: @category.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_category # 自分の世帯のカテゴリだけを探す
    @category = current_user.household.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon)
  end
end
