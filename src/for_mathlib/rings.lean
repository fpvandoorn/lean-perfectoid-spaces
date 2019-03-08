import ring_theory.ideal_operations ring_theory.localization data.equiv.algebra
import for_mathlib.subtype

universes u u₁ u₂ v

namespace ideal
open function

@[simp] lemma map_quotient_self {R : Type u} [comm_ring R] (I : ideal R) :
  ideal.map (ideal.quotient.mk I) I = ⊥ :=
lattice.eq_bot_iff.2 $ ideal.map_le_iff_le_comap.2 $
begin
  intros x hx,
  erw submodule.mem_bot I.quotient,
  exact ideal.quotient.eq_zero_iff_mem.2 hx, apply_instance
end

lemma eq_bot_or_top {K : Type u} [discrete_field K] (I : ideal K) :
  I = ⊥ ∨ I = ⊤ :=
begin
  rw classical.or_iff_not_imp_right,
  change _ ≠ _ → _,
  rw ideal.ne_top_iff_one,
  intro h1,
  apply le_antisymm, swap, exact lattice.bot_le,
  intros r hr,
  by_cases H : r = 0,
  simpa,
  simpa [H, h1] using submodule.smul_mem I r⁻¹ hr,
end

lemma eq_bot_of_prime {K : Type u} [discrete_field K] (I : ideal K) [h : I.is_prime] :
  I = ⊥ :=
classical.or_iff_not_imp_right.mp I.eq_bot_or_top h.1

-- This should just be the conjunction of
-- comap f ⊥ = ker f
-- ker f = ⊥  (for injective f)
lemma comap_bot_of_inj {R : Type u} [comm_ring R] {S : Type v} [comm_ring S] (f : R → S) [is_ring_hom f]
(h : injective f) :
  ideal.comap f ⊥ = ⊥ :=
lattice.eq_bot_iff.2 $
begin
  intros r hr,
  change r ∈ f ⁻¹' {0} at hr,
  simp at *,
  apply h,
  rw hr,
  symmetry,
  rw is_ring_hom.map_zero f,
end

end ideal
