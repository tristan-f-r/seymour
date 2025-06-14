import Seymour.Matroid.Operations.Sum3.CanonicalSigningSum3


/-! # Family of 3-sum-like matrices -/

/-! ## Definition -/

/-- Structural data of 3-sum-like matrices. -/
structure MatrixLikeSum3 (Xₗ Yₗ Xᵣ Yᵣ : Type) (c₀ c₁ : Xᵣ → ℚ) where
  Aₗ  : Matrix Xₗ Yₗ ℚ
  D   : Matrix Xᵣ Yₗ ℚ
  Aᵣ  : Matrix Xᵣ Yᵣ ℚ
  hAₗ : (Aₗ ⊟ D).IsTotallyUnimodular
  hD  : ∀ j, VecIsParallel3 (D · j) c₀ c₁ (c₀ - c₁)
  hAᵣ : (▮c₀ ◫ ▮c₁ ◫ ▮(c₀ - c₁) ◫ Aᵣ).IsTotallyUnimodular

/-- The resulting 3-sum-like matrix. -/
abbrev MatrixLikeSum3.matrix {Xₗ Yₗ Xᵣ Yᵣ : Type} {c₀ c₁ : Xᵣ → ℚ} (M : MatrixLikeSum3 Xₗ Yₗ Xᵣ Yᵣ c₀ c₁) :
    Matrix (Xₗ ⊕ Xᵣ) (Yₗ ⊕ Yᵣ) ℚ :=
  ⊞ M.Aₗ 0 M.D M.Aᵣ


/-! ## Pivoting -/

/-!
  In this section we prove that pivoting in the top-left block of a 3-sum-like matrix yields a 3-sum-like matrix.
-/

@[simp]
private abbrev matrixStackTwoValsTwoCols {X F : Type} [Zero F] [One F] [Neg F] (u : X → F) (v : X → F) (q : SignType) :
    Matrix (Unit ⊕ X) (Unit ⊕ Unit) F :=
  ▮(·.casesOn ↓1 u) ◫ ▮(·.casesOn ↓q.cast v)

private lemma Matrix.shortTableauPivot_col_in_ccVecSet_0 {X F : Type} [Field F] [DecidableEq X] {c₀ : X → F} {c₁ : X → F}
    (A : Matrix (Unit ⊕ X) (Unit ⊕ Unit) F)
    (hA₁₁ : A ◩() ◩() = 1) (hA₁₂ : A ◩() ◪() = 0) (hA₂₂ : VecIsParallel3 (A ◪· ◪()) c₀ c₁ (c₀ - c₁)) :
    VecIsParallel3 ((A.shortTableauPivot ◩() ◩()) ◪· ◪()) c₀ c₁ (c₀ - c₁) := by
  simp [hA₁₁, hA₁₂, hA₂₂]

set_option maxHeartbeats 0 in
private lemma matrixStackTwoValsTwoCols9_shortTableauPivot {X : Type} [DecidableEq X]
    {c₀ : X → ℚ} {c₁ : X → ℚ} (hcc : (▮c₀ ◫ ▮c₁ ◫ ▮(c₀ - c₁)).IsTotallyUnimodular)
    (u : X → ℚ) (v : X → ℚ)
    (hA : (matrixStackTwoValsTwoCols u v SignType.neg).IsTotallyUnimodular)
    (hucc : VecIsParallel3 u c₀ c₁ (c₀ - c₁)) (hvcc : VecIsParallel3 v c₀ c₁ (c₀ - c₁)) :
    VecIsParallel3 (((matrixStackTwoValsTwoCols u v SignType.neg).shortTableauPivot ◩() ◩()) ◪· ◪()) c₀ c₁ (c₀ - c₁) := by
  simp
  rw [show (fun x : X => v x + u x) = v + u by rfl]
  cases hucc with
  | inl hu0 =>
    simp [hu0]
    exact hvcc
  | inr huc =>
    cases hvcc with
    | inl hv0 =>
      simp [hv0]
      right
      exact huc
    | inr hvc =>
      rcases huc with (hu | hu | hu | hu | hu | hu) <;> rcases hvc with (hv | hv | hv | hv | hv | hv) <;> simp [hu, hv]
      all_goals
        unfold VecIsParallel3
        ring_nf
        try tauto
      · -- 1) hu : u = c₀, hv : v = c₀
        left
        ext i
        have hc₀i := hcc.apply i ◩◩()
        rw [Matrix.fromCols_apply_inl, Matrix.fromCols_apply_inl, Matrix.replicateCol_apply] at hc₀i
        obtain ⟨s₀, hs₀⟩ := hc₀i
        have hdet := hA.det ![◩(), ◪i] ![◩(), ◪()]
        simp [Matrix.det_fin_two, hu, hv] at hdet
        obtain ⟨s₂, hs₂⟩ := hdet
        cases s₀ <;> simp [←hs₀, ←sub_eq_add_neg] at hs₂ ⊢
      · -- 2) hu : u = c₀, hv : v = c₁
        -- requires additional assumption, otherwise counterexample:
        -- #eval (!![1, -1; 1, 0; 0, 1] : Matrix (Fin 3) (Fin 2) ℚ).testTotallyUnimodular -- true
        -- #eval (!![1, -1; 1, 0; 0, 1] : Matrix (Fin 3) (Fin 2) ℚ).shortTableauPivot 0 0 -- !![1, -1; -1, 1; 0, 1]
        -- #eval (!![1, -1; -1, 1; 0, 1] : Matrix (Fin 3) (Fin 2) ℚ).testTotallyUnimodular -- true
        -- #eval (!![1, 0, 1; 0, 1, -1] : Matrix (Fin 2) (Fin 3) ℚ).testTotallyUnimodular -- true
        have : ∃ i, ∃ j, c₀ i = 1 ∧ c₀ j = 0 ∧ ((c₁ i = 0 ∧ c₁ j = -1) ∨ (c₁ i = 1 ∧ c₁ j = 1)) := sorry
        -- #eval (!![1, -1; 1, 0; 0, -1] : Matrix (Fin 3) (Fin 2) ℚ).testTotallyUnimodular -- true
        -- #eval (!![1, -1; 1, 0; 0, -1] : Matrix (Fin 3) (Fin 2) ℚ).shortTableauPivot 0 0 -- !![1, -1; -1, 1; 0, -1]
        -- #eval (!![1, -1; -1, 1; 0, -1] : Matrix (Fin 3) (Fin 2) ℚ).testTotallyUnimodular -- true
        -- #eval (!![1, 0, 1; 0, -1, 1] : Matrix (Fin 2) (Fin 3) ℚ).testTotallyUnimodular -- true
        sorry
      · -- 3) hu : u = c₀, hv : v = c₀ - c₁
        sorry
      · -- 4) hu : u = -c₀, hv : v = -c₀
        -- same as 1)
        left
        ext i
        have hc₀i := hcc.apply i ◩◩()
        rw [Matrix.fromCols_apply_inl, Matrix.fromCols_apply_inl, Matrix.replicateCol_apply] at hc₀i
        obtain ⟨s₀, hs₀⟩ := hc₀i
        have hdet := hA.det ![◩(), ◪i] ![◩(), ◪()]
        simp [Matrix.det_fin_two, hu, hv] at hdet
        obtain ⟨s₂, hs₂⟩ := hdet
        cases s₀ <;> simp [←hs₀, ←sub_eq_add_neg] at hs₂ ⊢
      · -- 5) hu : u = -c₀, hv : v = -c₁
        sorry
      · -- 6) hu : u = -c₀, hv : v = c₁ - c₀
        sorry
      · -- 7) hu : u = c₁, hv : v = c₀
        sorry
      · -- 8) hu : u = c₁, hv : v = c₁
        -- similar to 1), but with c₁ instead of c₀
        left
        ext i
        have hc₁i := hcc.apply i ◩◪()
        rw [Matrix.fromCols_apply_inl, Matrix.fromCols_apply_inr, Matrix.replicateCol_apply] at hc₁i
        obtain ⟨s₁, hs₁⟩ := hc₁i
        have hdet := hA.det ![◩(), ◪i] ![◩(), ◪()]
        simp [Matrix.det_fin_two, hu, hv] at hdet
        obtain ⟨s₂, hs₂⟩ := hdet
        cases s₁ <;> simp [←hs₁, ←sub_eq_add_neg] at hs₂ ⊢
      · -- 9) hu : u = c₁, hv : v = c₁ - c₀
        sorry
      · -- 10) hu : u = -c₁, hv : v = -c₀
        sorry
      · -- 11) hu : u = -c₁, hv : v = -c₁
        -- same as 8)
        left
        ext i
        have hc₁i := hcc.apply i ◩◪()
        rw [Matrix.fromCols_apply_inl, Matrix.fromCols_apply_inr, Matrix.replicateCol_apply] at hc₁i
        obtain ⟨s₁, hs₁⟩ := hc₁i
        have hdet := hA.det ![◩(), ◪i] ![◩(), ◪()]
        simp [Matrix.det_fin_two, hu, hv] at hdet
        obtain ⟨s₂, hs₂⟩ := hdet
        cases s₁ <;> simp [←hs₁, ←sub_eq_add_neg] at hs₂ ⊢
      · -- 12) hu : u = -c₁, hv : v = c₀ - c₁
        sorry
      · -- 13) hu : u = c₀ - c₁, hv : v = c₀
        sorry
      · -- 14) hu : u = c₀ - c₁, hv : v = -c₁
        sorry
      · -- 15) hu : u = c₀ - c₁, hv : v = c₀ - c₁
        -- similar to on_goal 1, but with c₀ - c₁ (instead of c₀)
        left
        ext i
        have hc₀c₁i := hcc.apply i ◪()
        rw [Matrix.fromCols_apply_inr, Matrix.replicateCol_apply] at hc₀c₁i
        obtain ⟨s₁, hs₁⟩ := hc₀c₁i
        have hdet := hA.det ![◩(), ◪i] ![◩(), ◪()]
        simp [Matrix.det_fin_two, hu, hv] at hdet
        obtain ⟨s₂, hs₂⟩ := hdet
        rw [←sub_mul]
        rw [Pi.sub_apply] at hs₁
        rw [sub_eq_add_neg, neg_sub, ←mul_two] at hs₂
        cases s₁ <;> cases s₂ <;> simp [←hs₁] at hs₂ ⊢ <;> linarith only [hs₂]
      · -- 16) hu : u = c₁ - c₀, hv : v = -c₀
        sorry
      · -- 17) hu : u = c₁ - c₀, hv : v = c₁
        sorry
      · -- 18) hu : u = c₁ - c₀, hv : v = c₁ - c₀
        -- similar to 15), but with minor adjustments
        left
        ext i
        have hc₀c₁i := hcc.apply i ◪()
        rw [Matrix.fromCols_apply_inr, Matrix.replicateCol_apply] at hc₀c₁i
        obtain ⟨s₁, hs₁⟩ := hc₀c₁i
        have hdet := hA.det ![◩(), ◪i] ![◩(), ◪()]
        simp [Matrix.det_fin_two, hu, hv] at hdet
        obtain ⟨s₂, hs₂⟩ := hdet
        rw [←sub_mul]
        rw [←neg_sub, Pi.neg_apply, ←neg_eq_iff_eq_neg, Pi.sub_apply] at hs₁ -- note minor adjustments
        rw [sub_eq_add_neg, neg_sub, ←mul_two] at hs₂
        cases s₁ <;> cases s₂ <;> simp [←hs₁] at hs₂ ⊢ <;> linarith only [hs₂]

private lemma Matrix.IsTotallyUnimodular.shortTableauPivot_col_in_ccVecSet_9 {X : Type} [DecidableEq X]
    {c₀ : X → ℚ} {c₁ : X → ℚ} {A : Matrix (Unit ⊕ X) (Unit ⊕ Unit) ℚ} (hA : A.IsTotallyUnimodular)
    (hA₁₁ : A ◩() ◩() = 1) (hA₁₂ : A ◩() ◪() = -1)
    (hA₂₁ : VecIsParallel3 (A ◪· ◩()) c₀ c₁ (c₀ - c₁)) (hA₂₂ : VecIsParallel3 (A ◪· ◪()) c₀ c₁ (c₀ - c₁))
    (hcc : (▮c₀ ◫ ▮c₁ ◫ ▮(c₀ - c₁)).IsTotallyUnimodular) :
    VecIsParallel3 ((A.shortTableauPivot ◩() ◩()) ◪· ◪()) c₀ c₁ (c₀ - c₁) := by
  have A_eq : A = matrixStackTwoValsTwoCols (fun x => A ◪x ◩()) (fun x => A ◪x ◪()) SignType.neg
  · ext (_|_) (_|_)
    · exact hA₁₁
    · exact hA₁₂
    · simp
    · simp
  exact A_eq ▸ matrixStackTwoValsTwoCols9_shortTableauPivot hcc (A ◪· ◩()) (A ◪· ◪()) (A_eq ▸ hA) hA₂₁ hA₂₂

private lemma Matrix.IsTotallyUnimodular.shortTableauPivot_col_in_ccVecSet_1 {X F : Type} [Field F] [DecidableEq X]
    {c₀ : X → F} {c₁ : X → F} {A : Matrix (Unit ⊕ X) (Unit ⊕ Unit) F} (hA : A.IsTotallyUnimodular)
    (hA₁₁ : A ◩() ◩() = 1) (hA₁₂ : A ◩() ◪() = 1)
    (hA₂₁ : VecIsParallel3 (A ◪· ◩()) c₀ c₁ (c₀ - c₁)) (hA₂₂ : VecIsParallel3 (A ◪· ◪()) c₀ c₁ (c₀ - c₁))
    (hcc : (▮c₀ ◫ ▮c₁ ◫ ▮(c₀ - c₁)).IsTotallyUnimodular) :
    VecIsParallel3 ((A.shortTableauPivot ◩() ◩()) ◪· ◪()) c₀ c₁ (c₀ - c₁) := by
  sorry -- TODO reduce to `Matrix.IsTotallyUnimodular.shortTableauPivot_col_in_ccVecSet_9`

private lemma Matrix.IsTotallyUnimodular.shortTableauPivot_col_in_ccVecSet {X : Type} [DecidableEq X]
    {c₀ : X → ℚ} {c₁ : X → ℚ} {A : Matrix (Unit ⊕ X) (Unit ⊕ Unit) ℚ} (hA : A.IsTotallyUnimodular) (hA₁₁ : A ◩() ◩() ≠ 0)
    (hA₂₁ : VecIsParallel3 (A ◪· ◩()) c₀ c₁ (c₀ - c₁)) (hA₂₂ : VecIsParallel3 (A ◪· ◪()) c₀ c₁ (c₀ - c₁))
    (hcc : (▮c₀ ◫ ▮c₁ ◫ ▮(c₀ - c₁)).IsTotallyUnimodular) :
    VecIsParallel3 ((A.shortTableauPivot ◩() ◩()) ◪· ◪()) c₀ c₁ (c₀ - c₁) := by
  obtain ⟨sₗ, hsₗ⟩ := hA.apply ◩() ◩()
  cases sₗ with
  | zero =>
    exfalso
    exact hA₁₁ hsₗ.symm
  | pos =>
    obtain ⟨sᵣ, hsᵣ⟩ := hA.apply ◩() ◪()
    cases sᵣ with
    | zero => exact A.shortTableauPivot_col_in_ccVecSet_0 hsₗ.symm hsᵣ.symm hA₂₂
    | pos => exact hA.shortTableauPivot_col_in_ccVecSet_1 hsₗ.symm hsᵣ.symm hA₂₁ hA₂₂ hcc
    | neg => exact hA.shortTableauPivot_col_in_ccVecSet_9 hsₗ.symm hsᵣ.symm hA₂₁ hA₂₂ hcc
  | neg =>
    let q : Unit ⊕ X → ℚ := (·.casesOn ↓(-1) ↓1)
    have hq : ∀ i, q i ∈ SignType.cast.range
    · rintro (_|_) <;> simp [q]
    have hAq := hA.mul_rows hq
    obtain ⟨sᵣ, hsᵣ⟩ := hA.apply ◩() ◪()
    cases sᵣ with
    | zero =>
      convert
        (Matrix.of (fun i : Unit ⊕ X => fun j : Unit ⊕ Unit => A i j * q i)).shortTableauPivot_col_in_ccVecSet_0
          (by simp [←hsₗ, q])
          (by simp [←hsᵣ, q])
          (show VecIsParallel3 _ c₀ c₁ (c₀ - c₁) by simp [*, q, VecIsParallel3_neg])
        using 2
      simp only [Matrix.shortTableauPivot_eq, Matrix.of_apply, reduceCtorEq, ↓reduceIte]
      ring
    | pos =>
      convert
        hAq.shortTableauPivot_col_in_ccVecSet_9
          (by simp [←hsₗ, q])
          (by simp [←hsᵣ, q])
          (by simp [hA₂₁, q])
          (by simp [hA₂₂, q])
          hcc
        using 2
      simp only [Matrix.shortTableauPivot_eq, Matrix.of_apply, reduceCtorEq, ↓reduceIte]
      ring
    | neg =>
      convert
        hAq.shortTableauPivot_col_in_ccVecSet_1
          (by simp [←hsₗ, q])
          (by simp [←hsᵣ, q])
          (by simp [hA₂₁, q])
          (by simp [hA₂₂, q])
          hcc
        using 2
      simp only [Matrix.shortTableauPivot_eq, Matrix.of_apply, reduceCtorEq, ↓reduceIte]
      ring

private abbrev Matrix.shortTableauPivotOuterRow {X Y : Type} [DecidableEq X] [DecidableEq Y]
    (A : Matrix X Y ℚ) (r : Y → ℚ) (y : Y) :
    Matrix X Y ℚ :=
  ((▬r ⊟ A).shortTableauPivot ◩() y).toRows₂

private lemma MatrixLikeSum3.shortTableauPivot_Aₗ_eq {Xₗ Yₗ Xᵣ Yᵣ : Type} [DecidableEq Xₗ] [DecidableEq Yₗ] [DecidableEq Xᵣ]
    {c₀ c₁ : Xᵣ → ℚ} (M : MatrixLikeSum3 Xₗ Yₗ Xᵣ Yᵣ c₀ c₁) (x : Xₗ) (y : Yₗ) :
    M.Aₗ.shortTableauPivot x y = ((M.Aₗ ⊟ M.D).shortTableauPivot ◩x y).toRows₁ := by
  ext
  simp

private lemma MatrixLikeSum3.shortTableauPivot_D_eq {Xₗ Yₗ Xᵣ Yᵣ : Type} [DecidableEq Xₗ] [DecidableEq Yₗ] [DecidableEq Xᵣ]
    {c₀ c₁ : Xᵣ → ℚ} (M : MatrixLikeSum3 Xₗ Yₗ Xᵣ Yᵣ c₀ c₁) (x : Xₗ) (y : Yₗ) :
    M.D.shortTableauPivotOuterRow (M.Aₗ x) y = ((M.Aₗ ⊟ M.D).shortTableauPivot ◩x y).toRows₂ := by
  ext
  simp

private lemma MatrixLikeSum3.shortTableauPivot_hAₗ {Xₗ Yₗ Xᵣ Yᵣ : Type} [DecidableEq Xₗ] [DecidableEq Yₗ] [DecidableEq Xᵣ]
    {c₀ c₁ : Xᵣ → ℚ} (M : MatrixLikeSum3 Xₗ Yₗ Xᵣ Yᵣ c₀ c₁) {x : Xₗ} {y : Yₗ} (hxy : M.Aₗ x y ≠ 0) :
    (M.Aₗ.shortTableauPivot x y ⊟ M.D.shortTableauPivotOuterRow (M.Aₗ x) y).IsTotallyUnimodular := by
  rw [M.shortTableauPivot_D_eq x y, M.shortTableauPivot_Aₗ_eq x y, Matrix.fromRows_toRows]
  exact M.hAₗ.shortTableauPivot hxy

private lemma MatrixLikeSum3.shortTableauPivot_D_cols_in_ccVecSet {Xₗ Yₗ Xᵣ Yᵣ : Type}
    [DecidableEq Xₗ] [DecidableEq Yₗ] [DecidableEq Xᵣ]
    {c₀ c₁ : Xᵣ → ℚ} (M : MatrixLikeSum3 Xₗ Yₗ Xᵣ Yᵣ c₀ c₁) {x : Xₗ} {y : Yₗ} (hxy : M.Aₗ x y ≠ 0) (j : Yₗ) :
    VecIsParallel3 ((M.D.shortTableauPivotOuterRow (M.Aₗ x) y) · j) c₀ c₁ (c₀ - c₁) := by
  if hjy : j = y then
    have hAxy : M.Aₗ x y = 1 ∨ M.Aₗ x y = -1
    · obtain ⟨s, hs⟩ := M.hAₗ.apply ◩x y
      cases s <;> tauto
    have hPC : VecIsParallel3 (-M.D · y / M.Aₗ x y) c₀ c₁ (c₀ - c₁)
    · cases hAxy with
      | inl h1 =>
        simp only [h1, div_one]
        exact VecIsParallel3_neg (M.hD y)
      | inr h9 =>
        simp only [h9, neg_div_neg_eq, div_one]
        exact M.hD y
    simpa [hjy] using hPC
  else
    let A : Matrix (Unit ⊕ Xᵣ) (Unit ⊕ Unit) ℚ :=
      Matrix.of (fun u : Unit ⊕ Unit => ·.casesOn (u.casesOn ↓↓(M.Aₗ x y) ↓↓(M.Aₗ x j)) (u.casesOn ↓(M.D · y) ↓(M.D · j)))
    have hA : A.IsTotallyUnimodular
    · convert M.hAₗ.submatrix (fun i : Unit ⊕ Xᵣ => i.map ↓x id) (fun u : Unit ⊕ Unit => u.casesOn ↓y ↓j)
      aesop
    simpa [hjy] using hA.shortTableauPivot_col_in_ccVecSet hxy (M.hD y) (M.hD j) (M.hAᵣ.submatrix id Sum.inl)

def MatrixLikeSum3.shortTableauPivot {Xₗ Yₗ Xᵣ Yᵣ : Type} [DecidableEq Xₗ] [DecidableEq Yₗ] [DecidableEq Xᵣ]
    {c₀ c₁ : Xᵣ → ℚ} (M : MatrixLikeSum3 Xₗ Yₗ Xᵣ Yᵣ c₀ c₁) {x : Xₗ} {y : Yₗ} (hxy : M.Aₗ x y ≠ 0) :
    MatrixLikeSum3 Xₗ Yₗ Xᵣ Yᵣ c₀ c₁ where
  Aₗ  := M.Aₗ.shortTableauPivot x y
  D   := M.D.shortTableauPivotOuterRow (M.Aₗ x) y
  Aᵣ  := M.Aᵣ
  hAₗ := M.shortTableauPivot_hAₗ hxy
  hD  := M.shortTableauPivot_D_cols_in_ccVecSet hxy
  hAᵣ := M.hAᵣ


/-! ## Total unimodularity -/

/-!
  In this section we prove that every 3-sum-like matrix is totally unimodular.
-/

/-- Every 3-sum-like matrix is totally unimodular. -/
lemma MatrixLikeSum3.IsTotallyUnimodular {Xₗ Yₗ Xᵣ Yᵣ : Type} {c₀ c₁ : Xᵣ → ℚ} (M : MatrixLikeSum3 Xₗ Yₗ Xᵣ Yᵣ c₀ c₁) :
    M.matrix.IsTotallyUnimodular :=
  sorry  -- todo: adapt proof of total unimodularity of 2-sum


/-! ## Implications for canonical signing of 3-sum of matrices -/

/-!
  In this section we prove that 3-sums of matrices belong to the family of 3-sum-like matrices.
-/

/-- Convert a canonical signing of 3-sum of matrices to a 3-sum-like matrix. -/
noncomputable def MatrixSum3.IsCanonicalSigning.toMatrixLikeSum3 {Xₗ Yₗ Xᵣ Yᵣ : Type}
    [DecidableEq Xₗ] [DecidableEq Yₗ] [DecidableEq Xᵣ] [DecidableEq Yᵣ]
    {S : MatrixSum3 Xₗ Yₗ Xᵣ Yᵣ ℚ} (hS : S.IsCanonicalSigning) :
    MatrixLikeSum3 (Xₗ ⊕ Fin 1) (Yₗ ⊕ Fin 2) (Fin 2 ⊕ Xᵣ) (Fin 1 ⊕ Yᵣ) S.c₀ S.c₁ where
  Aₗ := S.Aₗ
  D := S.D
  Aᵣ := S.Aᵣ
  hAₗ := hS.Aₗ_D_isTotallyUnimodular
  hD := hS.D_eq_cols
  hAᵣ := hS.c₀_c₁_c₂_Aᵣ_isTotallyUnimodular

/-- The canonical signing of a 3-sum of matrices is totally unimodular. -/
lemma MatrixSum3.IsCanonicalSigning.IsTotallyUnimodular {Xₗ Yₗ Xᵣ Yᵣ : Type}
    [DecidableEq Xₗ] [DecidableEq Yₗ] [DecidableEq Xᵣ] [DecidableEq Yᵣ]
    {S : MatrixSum3 Xₗ Yₗ Xᵣ Yᵣ ℚ} (hS : S.IsCanonicalSigning) :
    S.matrix.IsTotallyUnimodular :=
  hS.toMatrixLikeSum3.IsTotallyUnimodular

/-- If the reconstructed summands of a 3-sum have TU signings, then the canonical signing of the 3-sum has a TU signing. -/
lemma MatrixSum3.HasCanonicalSigning.HasTuSigning {Xₗ Yₗ Xᵣ Yᵣ : Type}
    [DecidableEq Xₗ] [DecidableEq Yₗ] [DecidableEq Xᵣ] [DecidableEq Yᵣ]
    {S : MatrixSum3 Xₗ Yₗ Xᵣ Yᵣ Z2} (hS : S.HasCanonicalSigning) :
    S.matrix.HasTuSigning :=
  ⟨(S.toCanonicalSigning hS.left.left hS.left.right).matrix, hS.isCanonicalSigning.IsTotallyUnimodular, hS.toCanonicalSigning⟩
