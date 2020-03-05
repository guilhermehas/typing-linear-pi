open import Relation.Nullary.Decidable using (True; toWitness)
open import Function using (_∘_)

import Data.Product as Product
import Data.Unit as Unit
import Data.Fin as Fin
import Data.Nat as Nat
import Data.Bool as Bool
import Data.Vec as Vec
import Data.Vec.Relation.Unary.All as All

open Product using (Σ; Σ-syntax; _×_; _,_; proj₁)
open Unit using (⊤; tt)
open Nat using (ℕ; zero; suc)
open Fin using (Fin; zero; suc)
open Vec using (Vec; []; _∷_)
open All using (All; []; _∷_)

open import PiCalculus.Syntax
open Syntax
open Scoped
open import PiCalculus.LinearTypeSystem.Quantifiers

module PiCalculus.LinearTypeSystem (Ω : Quantifiers) where
open Quantifiers Ω

infixr 4 _w_⊢_⊠_
infixr 4 _w_∋_w_⊠_
infixr 10 base chan recv send

private
  variable
    i i' : I
    n : ℕ

data Type : Set where
  B[_]   : ℕ → Type
  C[_w_] : Type → Cs i → Type
  P[_&_] : Type → Type → Type

PreCtx : ℕ → Set
PreCtx = Vec Type

Ctx : ∀ {n} → Vec I n → Set
Ctx = All Cs

private
  variable
    γ : PreCtx n
    is : Vec I n
    Γ Δ Ξ Θ : Ctx is
    b : ℕ
    t t' : Type
    x y z : Cs i
    P Q : Scoped n

data _w_∋_w_⊠_ : PreCtx n → Ctx is
               → Type → Cs i
               → Ctx is → Set where

  zero : {Γ : Ctx is} {y z : Cs i}
       → {check : True (∙-compute y z)}
       → γ -, t w Γ -, proj₁ (toWitness check) ∋ t w y ⊠ Γ -, z

  suc : {Γ Δ : Ctx is} {x : Cs i} {x' : Cs i'}
      → γ w Γ ∋ t w x ⊠ Δ
      → γ -,  t' w Γ -, x' ∋ t w x ⊠ Δ -, x'

toFin : {γ : PreCtx n} {Γ Δ : Ctx is} {x : Cs i}
      → γ w Γ ∋ t w x ⊠ Δ
      → Fin n
toFin zero = zero
toFin (suc x) = suc (toFin x)

data _w_⊢_⊠_ : PreCtx n → Ctx is → Scoped n → Ctx is → Set where

  end : γ w Γ ⊢ 𝟘 ⊠ Γ

  base : γ -, B[ b ] w Γ -, 0∙ {i} ⊢ P     ⊠ Δ -, 0∙
       ---------------------------------------------
       → γ           w Γ       ⊢ +[] P ⊠ Δ

  chan : (t : Type) (m : Cs i') (μ : Cs i)
       → γ -, C[ t w m ] w Γ -, μ ⊢ P     ⊠ Δ -, 0∙
       --------------------------------------------
       → γ               w Γ      ⊢ new P ⊠ Δ

  recv : {t : Type} {m : Cs i'}
       → (x : γ      w Γ       ∋ C[ t w m ] w +∙ {i} ⊠ Ξ)
       →      γ -, t w Ξ -, m  ⊢ P                   ⊠ Θ -, 0∙
       -------------------------------------------------------
       →      γ      w Γ       ⊢ toFin x ⦅⦆ P        ⊠ Θ

  send : {t : Type} {m : Cs i'}
       → (x : γ w Γ ∋ C[ t w m ] w -∙ {i}   ⊠ Δ)
       → (y : γ w Δ ∋ t          w m        ⊠ Ξ)
       →      γ w Ξ ⊢ P                     ⊠ Θ
       -----------------------------------------
       →      γ w Γ ⊢ toFin x ⟨ toFin y ⟩ P ⊠ Θ

  comp : γ w Γ ⊢ P     ⊠ Δ
       → γ w Δ ⊢ Q     ⊠ Ξ
       -------------------
       → γ w Γ ⊢ P ∥ Q ⊠ Ξ

_w_⊢_ : PreCtx n → Ctx is → Scoped n → Set
γ w Γ ⊢ P = γ w Γ ⊢ P ⊠ ε
