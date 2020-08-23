{-# OPTIONS --safe #-} -- --without-K #-}

open import Relation.Binary.PropositionalEquality using (_≡_; _≢_; sym; refl; subst; trans; cong)
open import Relation.Nullary using (Dec; yes; no)
open import Relation.Nullary.Decidable using (True; toWitness; fromWitness)
open import Function using (_∘_; id)

open import Data.Maybe using (nothing; just)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Unit using (⊤; tt)
open import Data.Nat as ℕ using (ℕ; zero; suc)
open import Data.Product as Product using (Σ-syntax; ∃-syntax; _×_; _,_; proj₂; proj₁)
open import Data.Vec as Vec using (Vec; []; _∷_)
open import Data.Vec.Relation.Unary.All as All using (All; []; _∷_)
open import Data.Fin as Fin using (Fin ; zero ; suc)
import Data.Nat.Properties as ℕₚ
import Data.Vec.Relation.Unary.All.Properties as Allₚ
import Data.Product.Properties as Productₚ


import PiCalculus.Syntax
open PiCalculus.Syntax.Scoped
open import PiCalculus.Splits
open import PiCalculus.Semantics
open import PiCalculus.LinearTypeSystem.Algebras

module PiCalculus.LinearTypeSystem.ContextLemmas (Ω : Algebras) where
open Algebras Ω
open import PiCalculus.LinearTypeSystem Ω

private
  variable
    n m l : ℕ
    idxs idxsₗ idxsᵣ : Idxs n
    γ : PreCtx n
    idx idx' : Idx
    t : Type
    P Q : Scoped n
    i j : Fin n
    js : Vec (Fin n) m
    Γ Δ Ξ Θ xs : Ctx idxs
    x x' y z : Usage idx ²

data _≔_⊗_ : Ctx idxs → Ctx idxs → Ctx idxs → Set where
  []  : [] ≔ [] ⊗ []
  _,_ : Γ ≔ Δ ⊗ Ξ → x ≔ y ∙² z → (Γ -, x) ≔ (Δ -, y) ⊗ (Ξ -, z)

⊗-get : {idxs : Idxs n} {Γ Δ Ξ : Ctx idxs} (i : Fin n) → Γ ≔ Δ ⊗ Ξ → All.lookup i Γ ≔ All.lookup i Δ ∙² All.lookup i Ξ
⊗-get zero (Γ≔ , x≔) = x≔
⊗-get (suc i) (Γ≔ , x) = ⊗-get i Γ≔

⊗-idˡ : {idxs : Idxs n} {Γ : Ctx idxs} → Γ ≔ ε {idxs = idxs} ⊗ Γ
⊗-idˡ {Γ = []} = []
⊗-idˡ {Γ = Γ -, x} = ⊗-idˡ , ∙²-idˡ

⊗-unique : {Γ Γ' Δ Ξ  : Ctx idxs} → Γ' ≔ Δ ⊗ Ξ → Γ ≔ Δ ⊗ Ξ → Γ' ≡ Γ
⊗-unique [] [] = refl
⊗-unique (Γ'≔ , x'≔) (Γ≔ , x≔) rewrite ⊗-unique Γ'≔ Γ≔ | ∙²-unique x'≔ x≔ = refl

⊗-uniqueˡ : {Γ Δ Δ' Ξ  : Ctx idxs} → Γ ≔ Δ' ⊗ Ξ → Γ ≔ Δ ⊗ Ξ → Δ' ≡ Δ
⊗-uniqueˡ [] [] = refl
⊗-uniqueˡ (Δ'≔ , y'≔) (Δ≔ , y≔) rewrite ⊗-uniqueˡ Δ'≔ Δ≔ | ∙²-uniqueˡ y'≔ y≔ = refl

⊗-comm : {Γ Δ Ξ : Ctx idxs} → Γ ≔ Δ ⊗ Ξ → Γ ≔ Ξ ⊗ Δ
⊗-comm [] = []
⊗-comm (Γ≔ , x≔) = ⊗-comm Γ≔ , ∙²-comm x≔

⊗-assoc : {Γₘ Γₗ Γᵣ Γₗₗ Γₗᵣ : Ctx idxs}
        → Γₘ ≔ Γₗ ⊗ Γᵣ → Γₗ ≔ Γₗₗ ⊗ Γₗᵣ → Σ[ Γᵣ' ∈ Ctx idxs ] (Γₘ ≔ Γₗₗ ⊗ Γᵣ' × Γᵣ' ≔ Γₗᵣ ⊗ Γᵣ)
⊗-assoc [] [] = [] , [] , []
⊗-assoc (Γₘ≔ , xₘ≔) (Γₗ≔ , xₗ≔) with ⊗-assoc Γₘ≔ Γₗ≔ | ∙²-assoc xₘ≔ xₗ≔
... | (_ , Γₘ'≔ , Γᵣ'≔)  | (_ , xₘ'≔ , xᵣ'≔) = _ , ((Γₘ'≔ , xₘ'≔) , (Γᵣ'≔ , xᵣ'≔))

⊗-assoc⁻¹ : ∀ {x y z u v : Ctx idxs} → x ≔ y ⊗ z → z ≔ u ⊗ v → ∃[ w ] (x ≔ w ⊗ v × w ≔ y ⊗ u)
⊗-assoc⁻¹ a b = let _ , a' , b' = ⊗-assoc (⊗-comm a) (⊗-comm b) in _ , ⊗-comm a' , ⊗-comm b'

⊗-comp : {Γ Δₗ Δᵣ Δ Ξ Θ : Ctx idxs}
       → Γ ≔ Δₗ ⊗ Ξ → Ξ ≔ Δᵣ ⊗ Θ
       → Γ ≔ Δ  ⊗ Θ → Δ ≔ Δₗ ⊗ Δᵣ
⊗-comp l≔ r≔ Γ≔ with ⊗-assoc (⊗-comm l≔) (⊗-comm r≔)
⊗-comp l≔ r≔ Γ≔ | _ , Γ'≔ , R'≔ rewrite ⊗-uniqueˡ Γ≔ (⊗-comm Γ'≔) = ⊗-comm R'≔

⊗-idʳ : {Γ : Ctx idxs} → Γ ≔ Γ ⊗ ε
⊗-idʳ = ⊗-comm ⊗-idˡ

⊗-mut-cancel : ∀ {x y y' z : Ctx idxs} → x ≔ y ⊗ z → z ≔ y' ⊗ x → x ≡ z
⊗-mut-cancel [] [] = refl
⊗-mut-cancel (Γ≔ , x≔) (Ξ≔ , z≔) rewrite ⊗-mut-cancel Γ≔ Ξ≔ | ∙²-mut-cancel x≔ z≔ = refl

∋-≡Idx : {idxs : Idxs n} {i : Fin n} {Γ Δ : Ctx idxs} {x : Usage idx ²}
       → Γ ∋[ i ] x ▹ Δ → Vec.lookup idxs i ≡ idx
∋-≡Idx (zero x) = refl
∋-≡Idx (suc s) rewrite ∋-≡Idx s = refl

∋-≡Type : γ ∋[ i ] t → Vec.lookup γ i ≡ t
∋-≡Type zero = refl
∋-≡Type (suc t) rewrite ∋-≡Type t = refl

≡Type-∋ : Vec.lookup γ i ≡ t → γ ∋[ i ] t
≡Type-∋ {γ = _ -, _} {i = zero} refl = zero
≡Type-∋ {γ = _ -, _} {i = suc i} eq = suc (≡Type-∋ eq)

∋-frame : {idxs : Idxs n} {Γ Θ Δ Ξ Ψ : Ctx idxs} {x : Usage idx ²}
        → Γ ≔ Δ ⊗ Θ → Ξ ≔ Δ ⊗ Ψ
        → Γ ∋[ i ] x ▹ Θ
        → Ξ ∋[ i ] x ▹ Ψ

∋-frame (Γ≔ , x≔) (Ξ≔ , x'≔) (zero xyz)
  rewrite ⊗-uniqueˡ Γ≔ ⊗-idˡ | ⊗-unique Ξ≔ ⊗-idˡ
  | ∙²-uniqueˡ x≔ xyz = zero x'≔
∋-frame (Γ≔ , x≔) (Ξ≔ , x'≔) (suc x)
  rewrite ∙²-uniqueˡ x≔ ∙²-idˡ | ∙²-unique x'≔ ∙²-idˡ
  = suc (∋-frame Γ≔ Ξ≔ x)

∋-⊗ : {Γ Ξ : Ctx idxs}
    → Γ ∋[ i ] x ▹ Ξ
    → Σ[ Δ ∈ Ctx idxs ]
      (Γ ≔ Δ ⊗ Ξ × Δ ∋[ i ] x ▹ ε {idxs = idxs})
∋-⊗ (zero x) = _ , (⊗-idˡ , x) , zero ∙²-idʳ
∋-⊗ (suc s) with ∋-⊗ s
∋-⊗ (suc s) | _ , Γ≔ , Δ≔ = _ , (Γ≔ , ∙²-idˡ) , suc Δ≔

module _ where
  ⊇-frame : {idxs : Idxs n} {Γ Θ Δ Ξ Ψ : Ctx idxs}
          → Γ ≔ Δ ⊗ Θ → Ξ ≔ Δ ⊗ Ψ
          → Γ ⊇[ js ] xs ▹ Θ
          → Ξ ⊇[ js ] xs ▹ Ψ

  ⊇-⊗ : {Γ Ξ : Ctx idxs}
      → Γ ⊇[ js ] xs ▹ Ξ
      → Σ[ Δ ∈ Ctx idxs ]
        (Γ ≔ Δ ⊗ Ξ × Δ ⊇[ js ] xs ▹ ε {idxs = idxs})

  ⊇-⊗ [] = ε , ⊗-idˡ , []
  ⊇-⊗ (xs , x) with ⊇-⊗ xs | ∋-⊗ x
  ⊇-⊗ (xs , x) | Δ , p , r | Δ' , p' , r' =
    let Δ'' , p'' , r'' = ⊗-assoc⁻¹ p p' in
    Δ'' , p'' , (⊇-frame ⊗-idʳ r'' r , ∋-frame ⊗-idʳ ⊗-idʳ r')

  ⊇-frame Γ≔ Ξ≔ []
    rewrite ⊗-uniqueˡ Γ≔ ⊗-idˡ | ⊗-unique Ξ≔ ⊗-idˡ = []
  ⊇-frame Γ≔ Ξ≔ (xs , x) =
    let a , b , c = ∋-⊗ x
        d , e , f = ⊇-⊗ xs
        _ , g , h = ⊗-assoc⁻¹ e b
        _ , k , l = ⊗-assoc Ξ≔ (subst (λ ● → ● ≔ _ ⊗ _) (⊗-uniqueˡ g Γ≔) h)
    in ⊇-frame e k xs , ∋-frame b l x


∋-ℓ∅ : {idxs : Idxs n} {Γ : Ctx idxs} {i : Fin n} {idx : Idx}→ Vec.lookup idxs i ≡ idx → Γ ∋[ i ] ℓ∅ {idx} ▹ Γ
∋-ℓ∅ {Γ = _ -, _} {i = zero} refl = zero ∙²-idˡ
∋-ℓ∅ {Γ = _ -, _} {i = suc i} eq = suc (∋-ℓ∅ eq)

-- TODO: deprecate, convert to context first
∋-uniqueʳ : {i : Fin n} {idxs : Idxs n} {Γ Δ Ξ : Ctx idxs}
          → Γ ∋[ i ] x ▹ Δ → Γ ∋[ i ] x ▹ Ξ → Δ ≡ Ξ
∋-uniqueʳ (zero a) (zero b) rewrite ∙²-uniqueˡ (∙²-comm a) (∙²-comm b) = refl
∋-uniqueʳ (suc a) (suc b) rewrite ∋-uniqueʳ a b = refl

-- TODO: deprecate, convert to context first
∋-uniqueˡ : Γ ∋[ i ] x ▹ Δ → Ξ ∋[ i ] x ▹ Δ → Γ ≡ Ξ
∋-uniqueˡ (zero a) (zero b) rewrite ∙²-unique a b = refl
∋-uniqueˡ (suc a) (suc b) rewrite ∋-uniqueˡ a b = refl

∋-lookup-≡ : Γ ∋[ i ] x ▹ Δ → All.lookup i Γ ≔ x ∙² All.lookup i Δ
∋-lookup-≡ {Δ = _ -, _} (zero x) = x
∋-lookup-≡ {Δ = _ -, _} (suc s) = ∋-lookup-≡ s

∋-lookup-≢ : Γ ∋[ i ] x ▹ Δ → ∀ j → j ≢ i → All.lookup j Γ ≡ All.lookup j Δ
∋-lookup-≢ (zero x) zero j≢i = ⊥-elim (j≢i refl)
∋-lookup-≢ (suc xati) zero j≢i = refl
∋-lookup-≢ (zero x) (suc j) j≢i = refl
∋-lookup-≢ (suc xati) (suc j) j≢i = ∋-lookup-≢ xati j (j≢i ∘ cong suc)

∙²-⊗ : {Γ Δ Ξ : Ctx idxs}
     → Γ ∋[ i ] x ▹ ε → Δ ∋[ i ] y ▹ ε → Ξ ∋[ i ] z ▹ ε
     → x ≔ y ∙² z → Γ ≔ Δ ⊗ Ξ
∙²-⊗ (zero x) (zero y) (zero z) sp
  rewrite ∙²-unique x ∙²-idʳ | ∙²-unique y ∙²-idʳ | ∙²-unique z ∙²-idʳ = ⊗-idˡ , sp
∙²-⊗ (suc Γ≔) (suc Δ≔) (suc Ξ≔) sp = ∙²-⊗ Γ≔ Δ≔ Ξ≔ sp , ∙²-idˡ

diamond : {Γ Ξ Ψ : Ctx idxs}
        → i ≢ j
        → Γ ∋[ j ] x ▹ Ξ
        → Γ ∋[ i ] y ▹ Ψ
        → Σ[ Θ ∈ Ctx idxs ]
        ( Ξ ∋[ i ] y ▹ Θ
        × Ψ ∋[ j ] x ▹ Θ
        )
diamond i≢j (zero _) (zero _) = ⊥-elim (i≢j refl)
diamond i≢j (zero x) (suc ∋i) = _ , suc ∋i , zero x
diamond i≢j (suc ∋j) (zero x) = _ , zero x , suc ∋j
diamond i≢j (suc ∋j) (suc ∋i) with diamond (i≢j ∘ cong suc) ∋j ∋i
diamond i≢j (suc ∋j) (suc ∋i) | _ , ∋i' , ∋j' = _ , suc ∋i' , suc ∋j'

outer-diamond : {Γ Ξ Ψ Θ ΞΔ Δ ΨΔ : Ctx idxs}
              → i ≢ j
              → Γ ∋[ i ] x ▹ Ξ → Γ ∋[ j ] y ▹ Ψ
              → Ξ ∋[ j ] y ▹ Θ → Ψ ∋[ i ] x ▹ Θ
              → Ξ ≔ ΞΔ ⊗ Δ → Ψ ≔ ΨΔ ⊗ Δ
              → Σ[ ΘΔ ∈ Ctx idxs ] (Θ ≔ ΘΔ ⊗ Δ)
outer-diamond i≢j (zero _) (zero _) (zero _) (zero _) a b = ⊥-elim (i≢j refl)
outer-diamond i≢j (zero x₁) (suc ∋j) (suc ∈j) (zero x) (as , a) (bs , b) = _ , (bs , a)
outer-diamond i≢j (suc ∋i) (zero ∋j) (zero ∈j) (suc ∈i) (as , a) (bs , b) = _ , (as , b)
outer-diamond i≢j (suc ∋i) (suc ∋j) (suc ∈j) (suc ∈i) (as , a) (bs , b) with outer-diamond (i≢j ∘ cong suc) ∋i ∋j ∈j ∈i as bs
outer-diamond i≢j (suc ∋i) (suc ∋j) (suc ∈j) (suc ∈i) (as , a) (bs , b) | _ , s = _ , (s , a)

reverse : {Γ ΓΞ Ξ ΞΨ Ψ : Ctx idxs}
        → Γ ≔ ΓΞ ⊗ Ξ
        → Ξ ≔ ΞΨ ⊗ Ψ
        → Σ[ Θ ∈ Ctx idxs ]
        ( Γ ≔ ΞΨ ⊗ Θ
        × Θ ≔ ΓΞ ⊗ Ψ
        )
reverse Γ≔ΓΞ∙Ξ Ξ≔ΞΨ∙Ψ =
  let _ , Γ≔ΞΨ∙Θ , Θ≔Ψ∙ΓΞ = ⊗-assoc (⊗-comm Γ≔ΓΞ∙Ξ) Ξ≔ΞΨ∙Ψ in
  _ , Γ≔ΞΨ∙Θ , ⊗-comm Θ≔Ψ∙ΓΞ

boil : {Γ Ξ ΞΨ Θ Ψ ΘΨ : Ctx idxs}
     → Γ ∋[ i ] x ▹ Θ
     → Γ ∋[ i ] y ▹ Ξ
     → Ξ ≔ ΞΨ ⊗ Ψ
     → Θ ≔ ΘΨ ⊗ Ψ
     → All.lookup i ΘΨ ≡ ℓ∅
     → ∃[ z ] (x ≔ y ∙² z)
boil {i = zero} (zero a) (zero b) (_ , c) (_ , d) refl rewrite ∙²-unique d ∙²-idˡ with ∙²-assoc⁻¹ b c
boil {i = zero} (zero a) (zero b) (_ , c) (_ , d) refl | _ , e , f rewrite ∙²-uniqueˡ e a = _ , f
boil {i = suc i} (suc a) (suc b) (c , _) (d , _) eq = boil a b c d eq

split : x ≔ y ∙² z
      → Γ ∋[ i ] x ▹ Ξ
      → ∃[ Δ ] (Γ ∋[ i ] y ▹ Δ × Δ ∋[ i ] z ▹ Ξ)
split s (zero x) = let _ , x' , s' = ∙²-assoc x s in _ , zero x' , zero s'
split s (suc x) with split s x
split s (suc x) | _ , y , z = _ , suc y , suc z

split-ℓ∅ : {Γ ΓΨ Ψ ΓΘ Θ ΘΨ : Ctx idxs}
        → Γ ≔ ΓΨ ⊗ Ψ
        → Γ ≔ ΓΘ ⊗ Θ
        → Θ ≔ ΘΨ ⊗ Ψ
        → All.lookup i ΓΨ ≡ ℓ∅
        → All.lookup i ΓΘ ≡ ℓ∅ × All.lookup i ΘΨ ≡ ℓ∅
split-ℓ∅ {i = zero} (a , x) (b , y) (c , z) refl rewrite ∙²-unique x ∙²-idˡ with ∙²-mut-cancel y z
split-ℓ∅ {i = zero} (a , x) (b , y) (c , z) refl | refl = ∙²-uniqueˡ y ∙²-idˡ , ∙²-uniqueˡ z ∙²-idˡ
split-ℓ∅ {i = suc i} (a , _) (b , _) (c , _) eq = split-ℓ∅ a b c eq

⊗-merge : ∀ {Γₗ Δₗ Ξₗ : Ctx idxsₗ} {Γᵣ Δᵣ Ξᵣ : Ctx idxsᵣ}
         → (ρ : n + m ≔ l)
         → Γₗ ≔ Δₗ ⊗ Ξₗ
         → Γᵣ ≔ Δᵣ ⊗ Ξᵣ
         → all-merge ρ Γₗ Γᵣ ≔ all-merge ρ Δₗ Δᵣ ⊗ all-merge ρ Ξₗ Ξᵣ
⊗-merge zero [] [] = []
⊗-merge (left ρ) (xs , x) ys = ⊗-merge ρ xs ys , x
⊗-merge (right ρ) xs (ys , y) = ⊗-merge ρ xs ys , y

⊗-split : (ρ : n + m ≔ l)
        → ∀ {Γₗ Δₗ Ξₗ : Ctx idxsₗ} {Γᵣ Δᵣ Ξᵣ : Ctx idxsᵣ}
        → all-merge ρ Γₗ Γᵣ ≔ all-merge ρ Δₗ Δᵣ ⊗ all-merge ρ Ξₗ Ξᵣ
        → Γₗ ≔ Δₗ ⊗ Ξₗ × Γᵣ ≔ Δᵣ ⊗ Ξᵣ
⊗-split zero {[]} {[]} {[]} {[]} {[]} {[]} [] = [] , []
⊗-split (left ρ) {_ -, _} {_ -, _} {_ -, _} (xs , x) = Product.map (_, x) id (⊗-split ρ xs)
⊗-split (right ρ) {Γᵣ = _ -, _} {_ -, _} {_ -, _} (xs , x) = Product.map id (_, x) (⊗-split ρ xs)

⊢-⊗ : {γ : PreCtx n} {idxs : Idxs n} {Γ Ξ : Ctx idxs} → γ ； Γ ⊢ P ▹ Ξ → Σ[ Δ ∈ Ctx idxs ] (Γ ≔ Δ ⊗ Ξ)
⊢-⊗ 𝟘 = ε , ⊗-idˡ
⊢-⊗ (ν t μ ⊢P) with ⊢-⊗ ⊢P
⊢-⊗ (ν t μ ⊢P) | (_ -, _) , (P≔ , _) = _ , P≔
⊢-⊗ ((_ , x) ⦅⦆ ⊢P) with ⊢-⊗ ⊢P
⊢-⊗ (_⦅⦆_ {ts = ts} (_ , x) ⊢P) | Δ , P≔
  rewrite sym (all-merge∘split (left-first′ _ _) (Vec.map (proj₁ ∘ proj₂) ts) _ Δ) =
  let _ , x≔ , _ = ∋-⊗ x
      _ , xP≔ , _ = ⊗-assoc⁻¹ x≔ (proj₂ (⊗-split (left-first′ _ _) P≔))
   in _ , xP≔

⊢-⊗ ((_ , x) ⟨ _ , ys ⟩ ⊢P) =
  let _ , x≔ , _ = ∋-⊗ x
      _ , ys≔ , _ = ⊇-⊗ ys
      _ , P≔ = ⊢-⊗ ⊢P
      _ , xys≔ , _ = ⊗-assoc⁻¹ x≔ ys≔
      _ , Pxys≔ , _ = ⊗-assoc⁻¹ xys≔ P≔
   in _ , Pxys≔
⊢-⊗ (⊢P ∥ ⊢Q) =
  let _ , P≔ = ⊢-⊗ ⊢P
      _ , Q≔ = ⊢-⊗ ⊢Q
      _ , PQ≔ , _ = ⊗-assoc⁻¹ P≔ Q≔
   in _ , PQ≔

{-
∋-fromFin : {γ : PreCtx n} {idxs : Idxs n} {Γ : Ctx idxs}
          → ∀ i
          → {y z : Usage (Vec.lookup idxs i) ²}
          → All.lookup i Γ ≔ y ∙² z
          → γ ； Γ ∋[ i ] Vec.lookup γ i ； y ▹ all-update i z Γ
∋-fromFin {γ = γ -, t} {Γ = Γ -, x} zero split = zero , (zero split)
∋-fromFin {γ = γ -, t} {Γ = Γ -, x} (suc i) split = there (∋-fromFin i split)

#_ : {γ : PreCtx n} {idxs : Idxs n} {Γ : Ctx idxs}
   → ∀ m {m<n : True (m ℕₚ.<? n)}
   → let i = Fin.fromℕ< (toWitness m<n)
     in {y : Usage (Vec.lookup idxs i) ²}
   → {check : True (∙²-computeʳ (All.lookup i Γ) y)}
   → let z , _ = toWitness check
     in γ ； Γ ∋[ i ] Vec.lookup γ i ； y ▹ ctx-update i z Γ
(# m) {m<n} {check = check} =
  let _ , split = toWitness check
  in ∋-fromFin (Fin.fromℕ< (toWitness m<n)) split
-}
