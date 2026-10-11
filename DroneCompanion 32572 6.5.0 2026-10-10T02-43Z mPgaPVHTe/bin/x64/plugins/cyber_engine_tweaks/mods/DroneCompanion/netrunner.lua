return function(G)
  local M = {}

  local P = G.TDB .. "Net"

  local function ensure(id, kind)
    if TweakDB:GetRecord(id) == nil then TweakDB:CreateRecord(id, kind) end
  end

  local function cloneOnce(id, base)
    if TweakDB:GetRecord(id) == nil then TweakDB:CloneRecord(id, base) end
  end

  local function constantMod(id, modType, stat, value)
    ensure(id, "gamedataConstantStatModifier_Record")
    TweakDB:SetFlatNoUpdate(id .. ".modifierType", modType)
    TweakDB:SetFlatNoUpdate(id .. ".statType", stat)
    TweakDB:SetFlatNoUpdate(id .. ".value", value)
    TweakDB:Update(id)
  end

  local function hackSE(id, base, duration)
    cloneOnce(id, base)
    TweakDB:SetFlatNoUpdate(id .. ".gameplayTags", { "Debuff", "NPCQuickhack" })
    TweakDB:SetFlat(id .. ".duration", id .. "Dur")
    ensure(id .. "Dur", "gamedataStatModifierGroup_Record")
    TweakDB:SetFlatNoUpdate(id .. "Dur.statModsLimit", -1)
    constantMod(id .. "DurStat", "Additive", "BaseStats.MaxDuration", duration)
    TweakDB:SetFlat(id .. "Dur.statModifiers", { id .. "DurStat" })
  end

  local function dotAttack(se, damageType, attackBase, strength)
    TweakDB:SetFlat(se .. ".packages", { se .. "Pkg" })
    cloneOnce(se .. "Pkg", "AIQuickHackStatusEffect.HackOverheat_inline0")
    TweakDB:SetFlat(se .. "Pkg.effectors", { se .. "Eff" })
    cloneOnce(se .. "Eff", "AIQuickHackStatusEffect.HackOverheat_inline1")
    TweakDB:SetFlatNoUpdate(se .. "Eff.prereqRecord", "Prereqs.AlwaysTruePrereq")
    TweakDB:SetFlat(se .. "Eff.attackRecord", se .. "Atk")
    cloneOnce(se .. "Atk", attackBase)
    TweakDB:SetFlatNoUpdate(se .. "Atk.effectName", "damage_over_time")
    TweakDB:SetFlatNoUpdate(se .. "Atk.effectTag", "default")
    cloneOnce(se .. "AtkCurve", "Character.NPC_Base_Curves_inline1")
    TweakDB:SetFlatNoUpdate(se .. "AtkCurve.refObject", "Root")
    TweakDB:SetFlat(se .. "AtkCurve.statType", damageType)
    constantMod(se .. "AtkMult", "Multiplier", damageType, strength)
    TweakDB:SetFlat(se .. "Atk.statModifiers", { se .. "AtkCurve", se .. "AtkMult" })
  end

  M.nextHackAt = {}
  M.hackIdx = {}

  function M.forget(rec)
    M.nextHackAt[rec] = nil
    M.hackIdx[rec] = nil
  end

  local ROTATION = {
    P .. "OverheatSE",
    "BaseStatusEffect.WeaponMalfunction",
    P .. "BlindSE",
    P .. "CrippleSE",
  }

  local UPLOAD = 1.2
  local RANGE = 30.0

  function M.tick()
    if not G.settings.androidHacks then return end
    local now = os.clock()
    local ses = Game.GetStatusEffectSystem()
    local combatSE = TweakDBID.new(G.TDB .. "InCombatSE")
    G.companion.eachActive(function(rec, ent, model)
      if model.chassis ~= "Android" then return end
      if (M.nextHackAt[rec] or 0) > now then return end
      local okAll = pcall(function()
        if not ses:HasStatusEffect(ent:GetEntityID(), combatSE) then return end
        local target = G.companion.targetEnt and G.companion.targetEnt[rec]
        if not IsDefined(target) or target:IsDead() then return end
        local d = Vector4.Distance(ent:GetWorldPosition(), target:GetWorldPosition())
        if d > RANGE then return end
        for n = 0, #ROTATION - 1 do
          local i = ((M.hackIdx[rec] or 0) + n) % #ROTATION + 1
          local se = ROTATION[i]
          if not ses:HasStatusEffect(target:GetEntityID(), TweakDBID.new(se)) then
            M.hackIdx[rec] = i
            M.nextHackAt[rec] = now + G.tuning.get("nethack")
            local tid = target:GetEntityID()
            G.Cron.After(UPLOAD, function()
              pcall(function()
                local t = Game.FindEntityByID(tid)
                if not IsDefined(t) or t:IsDead() then return end
                StatusEffectHelper.ApplyStatusEffect(t, TweakDBID.new(se))
              end)
            end)
            break
          end
        end
      end)
      if not okAll then M.nextHackAt[rec] = now + 4 end
    end)
  end

  function M.setup()
    if TweakDB:GetRecord("AIQuickHackStatusEffect.HackOverheat") == nil then
      G.log("netrunner SE setup skipped, base missing")
      return
    end

    hackSE(P .. "OverheatSE", "AIQuickHackStatusEffect.HackOverheat", 10)
    dotAttack(P .. "OverheatSE", "BaseStats.ThermalDamage",
      "Attacks.EnemyNetrunnerThermalDamageOverTime", 0.1)
    hackSE(P .. "BlindSE", "BaseStatusEffect.Blind", 8)
    hackSE(P .. "CrippleSE", "BaseStatusEffect.LocomotionMalfunction", 12)

    G.log("netrunner setup ok")
  end

  return M
end
