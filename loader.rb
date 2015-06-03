# Place this below Materials and above ALL other custom scripts in order to use
# Demiurge output in your game.

class << DataManager
  
  alias_method :en_d_dm_lnd, :load_normal_database
  def load_normal_database
    en_d_dm_lnd
    load_demiurge
  end
  
  alias_method :en_d_dm_lbtd, :load_battle_test_database
  def load_battle_test_database
    en_d_dm_lbtd
    load_demiurge
  end
  
  def load_demiurge
    $demiurge = load_data('Data/Demiurge.rvdata2')
    $data_actors.each { |a| a.note << $demiurge[:Actors][a.id] if a }
    $data_armors.each { |a| a.note << $demiurge[:Armors][a.id] if a }
    $data_classes.each { |c| c.note << $demiurge[:Classes][c.id] if c }
    $data_enemies.each { |e| e.note << $demiurge[:Enemies][e.id] if e }
    $data_items.each { |i| i.note << $demiurge[:Items][i.id] if i }
    $data_skills.each { |s| s.note << $demiurge[:Skills][s.id] if s }
    $data_states.each { |s| s.note << $demiurge[:States][s.id] if s }
    $data_tilesets.each { |t| t.note << $demiurge[:Tilesets][t.id] if t }
    $data_weapons.each { |w| w.note << $demiurge[:Weapons][w.id] if w }
  end
end

class Game_Map
  
  def setup(map_id)
    @map_id = map_id
    @map = load_data(sprintf("Data/Map%03d.rvdata2", @map_id))
    @map.note << $demiurge[:Maps][@map_id]
    @tileset_id = @map.tileset_id
    @display_x = 0
    @display_y = 0
    referesh_vehicles
    setup_events
    setup_scroll
    setup_parallax
    setup_battleback
    @need_refresh = false
  end
end
