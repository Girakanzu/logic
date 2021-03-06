defmodule Entice.Logic.VitalsTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Logic.Vitals
  alias Entice.Logic.Vitals.AliveBehaviour
  alias Entice.Logic.Vitals.DeadBehaviour

  setup do
    {:ok, e1, _pid} = Entity.start
    {:ok, e2, _pid} = Entity.start

    Entity.put_attribute(e1, %Level{level: 20})
    Entity.put_attribute(e2, %Level{level: 3})

    Vitals.register(e1)
    Vitals.register(e2)

    {:ok, [e1: e1, e2: e2]}
  end

  test "entity has AliveBehaviour", %{e1: e1} do
    assert Entity.has_behaviour?(e1, AliveBehaviour)
  end

  test "entity has health", %{e1: e1} do
    assert Entity.has_attribute?(e1, Health)
  end

  test "entity has health level 20", %{e1: e1} do
    assert {:ok, %Health{health: 480, max_health: 480}} = Entity.fetch_attribute(e1, Health)
  end

  test "entity has health level 3", %{e2: e2} do
    assert {:ok, %Health{health: 140, max_health: 140}} = Entity.fetch_attribute(e2, Health)
  end

  test "entity has mana", %{e1: e1} do
    assert Entity.has_attribute?(e1, Energy)
  end

  test "entity has morale", %{e1: e1} do
    assert Entity.has_attribute?(e1, Morale)
  end

  test "health & energy & morale are removed on termination", %{e1: e1} do
    Vitals.unregister(e1)
    assert not Entity.has_attribute?(e1, Health)
    assert not Entity.has_attribute?(e1, Energy)
    assert not Entity.has_attribute?(e1, Morale)
  end

  test "do damage on entity", %{e1: e1} do
    Vitals.damage(e1, 140)
    assert {:ok, %Health{health: 340, max_health: 480}} = Entity.fetch_attribute(e1, Health)
  end

  test "do damage on entity and heal the entity", %{e1: e1} do
    Vitals.damage(e1, 100)
    assert {:ok, %Health{health: 380, max_health: 480}} = Entity.fetch_attribute(e1, Health)
    Vitals.heal(e1, 100)
    assert {:ok, %Health{health: 480, max_health: 480}} = Entity.fetch_attribute(e1, Health)
  end

  test "heal entity and check if health <= max_health", %{e1: e1} do
    Vitals.heal(e1, 200)
    assert {:ok, %Health{health: 480, max_health: 480}} = Entity.fetch_attribute(e1, Health)
  end

  test "entity dies and has -15 morale", %{e1: e1} do
    Vitals.damage(e1, 1000)
    assert Entity.has_behaviour?(e1, DeadBehaviour)
    assert {:ok, %Morale{morale: -15}} = Entity.fetch_attribute(e1, Morale)
  end

  test "resurrect entity with -15 morale", %{e1: e1} do
    Coordination.register_observer(self, __MODULE__)
    Coordination.register(e1, __MODULE__)
    Vitals.damage(e1, 1000)
    assert_receive {:entity_dead, %{entity_id: ^e1, attributes: %{}}}
    assert Entity.has_behaviour?(e1, DeadBehaviour)

    Vitals.resurrect(e1, 50, 50)
    assert_receive {:entity_resurrected, %{entity_id: ^e1, attributes: %{}}}
    assert Entity.has_behaviour?(e1, AliveBehaviour)
    assert {:ok, %Morale{morale: -15}} = Entity.fetch_attribute(e1, Morale)
  end

  test "resurrect entity with -15 morale and 50 percent of health and mana", %{e1: e1} do
    Vitals.damage(e1, 1000)
    assert Entity.has_behaviour?(e1, DeadBehaviour)
    Vitals.resurrect(e1, 50, 50)
    assert Entity.has_behaviour?(e1, AliveBehaviour)
    assert {:ok, %Morale{morale: -15}} = Entity.fetch_attribute(e1, Morale)
    assert {:ok, %Health{health: 204, max_health: 408}} = Entity.fetch_attribute(e1, Health)
    assert {:ok, %Energy{mana: 30, max_mana: 59}} = Entity.fetch_attribute(e1, Energy)
  end


  test "killing an entity", %{e1: e1} do
    Vitals.kill(e1)
    assert Entity.has_behaviour?(e1, DeadBehaviour)
  end


  test "recharging health", %{e1: e1} do
    assert {:ok, %Health{health: 480}} = Entity.fetch_attribute(e1, Health)

    Vitals.health_regeneration(e1, 10)
    Vitals.damage(e1, 10)

    assert {:ok, %Health{health: health}} = Entity.fetch_attribute(e1, Health)
    assert health <= 480

    :timer.sleep(1100)

    assert {:ok, %Health{health: 480}} = Entity.fetch_attribute(e1, Health)
  end


  test "recharging energy", %{e1: e1} do
    assert {:ok, %Energy{mana: 70}} = Entity.fetch_attribute(e1, Energy)

    Vitals.energy_regeneration(e1, 2)
    Entity.update_attribute(e1, Energy, fn ene -> %Energy{ene | mana: (ene.mana - 2)} end)

    assert {:ok, %Energy{mana: energy}} = Entity.fetch_attribute(e1, Energy)
    assert energy <= 70

    :timer.sleep(1100)

    assert {:ok, %Energy{mana: 70}} = Entity.fetch_attribute(e1, Energy)
  end
end
