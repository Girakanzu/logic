defmodule Entice.Logic.Npc do 
  alias Entice.Entity
  alias Entice.Logic.Player.Name
  alias Entice.Logic.Player.Position
  alias Entice.Logic.Player.MapInstance
  alias Entice.Logic.Player.Level
  alias Entice.Logic.Npc

  defstruct(npc_model_id: :dhuum)

  @doc "Prepares a single, simple player"
  def register(entity, map, name \\ "Dhuum", npc \\ %Npc{}) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.put(Name, %Name{name: name})
      |> Map.put(Position, %Position{pos: map.spawn})
      |> Map.put(MapInstance, %MapInstance{map: map})
      |> Map.put(Npc, npc)
      |> Map.put(Level, %Level{level: 20})
    end)
  end


  @doc "Removes all player attributes from the entity"
  def unregister(entity) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.delete(Name)
      |> Map.delete(Position)
      |> Map.delete(MapInstance)
      |> Map.delete(Npc)
      |> Map.delete(Level)
    end)
  end

  @doc "Returns all player related attributes as an attribute map"
  def attributes(entity),
  do: Entity.take_attributes(entity, [Name, Position, MapInstance, Level, Npc])

end