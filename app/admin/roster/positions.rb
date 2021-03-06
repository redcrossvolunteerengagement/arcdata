ActiveAdmin.register Roster::Position, as: 'Position' do

  menu parent: 'Roster'

  filter :chapter
  filter :name

  actions :all, except: [:destroy]

  controller do
    def resource_params
      request.get? ? [] : [params.require(:position).permit(:name, :vc_regex_raw, :hidden, :chapter_id, :watchfire_role, :role_ids => [])]
    end
  end

  form do |f|
    f.inputs
    f.inputs do
      f.input :roles, as: :check_boxes
    end
    f.actions
  end

end
