import topology.opens
import topology.uniform_space.cauchy
import topology.algebra.group

import for_mathlib.function
import for_mathlib.filter

open topological_space

-- predicates we need for topological rings

-- We need to think whether we could directly use the class t2_space (which is not using opens though)
definition is_hausdorff (α : Type*) [topological_space α] : Prop :=
  ∀ x y, x ≠ y → ∃ u v : opens α, x ∈ u ∧ y ∈ v ∧ u ∩ v = ∅

lemma continuous_of_const {α : Type*} {β : Type*}
  [topological_space α] [topological_space β]
  {f : α → β} (h : ∀a b, f a = f b) :
  continuous f :=
λ s _, by convert @is_open_const _ _ (∃ a, f a ∈ s); exact
  set.ext (λ a, ⟨λ fa, ⟨_, fa⟩,
    λ ⟨b, fb⟩, show f a ∈ s, from h b a ▸ fb⟩)

section
variables {α : Type*} {β : Type*} {γ : Type*} {δ : Type*}

variables [topological_space α] [topological_space β] [topological_space γ] [topological_space δ]

def continuous₂ (f : α → β → γ) := continuous (function.uncurry f)

lemma continuous₂_def (f : α → β → γ) : continuous₂ f ↔ continuous (function.uncurry f) := iff.rfl

lemma continuous₂_curry (f : α × β → γ) : continuous₂ (function.curry f) ↔ continuous f :=
by rw  [←function.uncurry_curry f] {occs := occurrences.pos [2]} ; refl

lemma continuous₂.comp {f : α → β → γ} {g : γ → δ}
  (hf : continuous₂ f)(hg : continuous g) :
continuous₂ (g ∘₂ f) :=
begin
  unfold continuous₂,
  rw function.uncurry_comp₂,
  exact hf.comp hg
end

section
open filter

/-
    f
  α → β
g ↓   ↓ h
  γ → δ
    i
-/
variables {g : α → γ} (eg : embedding g)
include eg

lemma embedding.nhds_eq_comap (a : α) : nhds a = comap g (nhds $ g a) :=
by rw [eg.2, nhds_induced_eq_comap]

variables {f : α → β} {i : γ → δ}
          {h : β → δ} (eh : embedding h)
          (H : h ∘ f = i ∘ g)
include eh H

lemma embedding.tendsto_iff (a : α) : continuous_at i (g a) → continuous_at f a:=
begin
  let N := nhds a, let Nf := nhds (f a),
  let Nhf := nhds (h $ f a), let Ng := nhds (g a),
  have Neq1 : Nf = comap h Nhf, from eh.nhds_eq_comap (f a),
  have Neq2 : N = comap g Ng, from eg.nhds_eq_comap a,
  intro hyp,
  replace hyp : Ng ≤ comap i Nhf,
  { unfold continuous_at at hyp,
    rw ← show h (f a) = i (g a), from congr_fun H a at hyp,
    rwa tendsto_iff_comap at hyp },
  rw calc
      continuous_at f a ↔ tendsto f N Nf : iff.rfl
      ... ↔ N ≤ comap f Nf : tendsto_iff_comap
      ... ↔ comap g Ng ≤ comap f (comap h Nhf) : by rw [Neq1, Neq2]
      ... ↔ comap g Ng ≤ comap g (comap i Nhf) : by rw comap_comm H,
  exact comap_mono hyp
end
end
end

namespace dense_embedding
open set function filter
variables {α : Type*} {β : Type*} {γ : Type*} {δ : Type*}
variables [topological_space α] [topological_space β] [topological_space γ] [topological_space δ]

variables {f : α → β} {g : α → γ} {h : β → δ} {i : γ → δ}
/-
    f
  α → β
g ↓   ↓ h
  γ → δ
    i
-/
-- The following lemma correct a typo in mathlib topology/maps.lean
protected lemma continuous' (df : dense_embedding f) : continuous f :=
continuous_iff_continuous_at.mpr $ λ a, df.continuous_at

-- TODO: The first item in the next proof should be extracted as a lemma about functions with dense image

lemma comp (df : dense_embedding f) (dh : dense_embedding h) : dense_embedding (h ∘ f) :=
{ dense :=
    begin
      intro,
      rw range_comp,
      have Hf : closure (range f) = univ,
        from eq_univ_of_forall df.dense,
      have Hh : closure (range h) = univ,
        from eq_univ_of_forall dh.dense,
      rw [← image_univ, ← Hf] at Hh,
      have : h '' (closure $ range f) ⊆ closure (h '' range f),
        from image_closure_subset_closure_image dh.continuous',
      have := closure_mono this,
      rw closure_closure at this,
      apply this,
      simp [Hh]
    end,
  inj :=  function.injective_comp dh.inj df.inj,
  induced := λ a, by rw [← comap_comap_comp, dh.induced, df.induced] }

-- The next lemma is dubious. Maybe it needs more assumptions.
lemma of_comm_square (dg : dense_embedding g) (di : dense_embedding i)
  (dh : dense_embedding h) (H : h ∘ f = i ∘ g) : dense_embedding f :=
sorry
end dense_embedding

section
open filter
variables  {α : Type*} [topological_space α] {β : Type*} [topological_space β] [discrete_topology β]

lemma continuous_into_discrete_iff (f : α → β) : continuous f ↔ ∀ b : β, is_open (f ⁻¹' {b}) :=
begin
  split,
  { intros hf b,
    exact hf _ (is_open_discrete _) },
  { intro h,
    rw continuous_iff_continuous_at,
    intro x,
    have key : f ⁻¹' {f x} ∈ nhds x,
      from mem_nhds_sets (h $ f x) (set.mem_insert (f x) ∅),
    calc map f (nhds x) ≤ pure (f x) : (tendsto_pure f (nhds x) (f x)).2 key
        ... ≤ nhds (f x) : pure_le_nhds _ }
end
end

def continuous_pi_prod {I : Type*} {R : I → Type*} {S : I → Type*} {T : I → Type*}
  [∀ i, topological_space (R i)] [∀ i, topological_space (S i)] [∀ i, topological_space (T i)]
  {f : Π (i : I), (R i) × (S i) → (T i)} (Hfi : ∀ i, continuous (f i)) :
continuous (λ rs i, f i ⟨rs.1 i, rs.2 i⟩ : (Π (i : I), R i) × (Π (i : I), S i) → Π (i : I), T i) :=
begin
  apply continuous_pi,
  intro i,
  have H : (λ (rs : (Π (i : I), R i) × Π (i : I), S i), f i (rs.fst i, rs.snd i)) =
  (f i) ∘ (λ (rs : (Π (i : I), R i) × Π (i : I), S i), (⟨rs.fst i, rs.snd i⟩ : R i × S i)) := rfl,
  rw H,
  apply continuous.comp,
    swap, exact Hfi i,
  apply continuous.prod_mk,
  sorry, sorry
end
