(**
  [TypeTheory.ALV1.CwF_SplitTypeCat_Defs]

  Part of the [TypeTheory] library (Ahrens, Lumsdaine, Voevodsky, 2015–present).
*)

(**

In this file, we give the definitions of _split type-categories_ (originally due to Cartmell, here following a version given by Pitts) and _categories with families_ (originally due to Dybjer, here following a formulation given by Fiore).

To facilitate comparing them afterwards, we split up their definitions in a slightly unusual way, starting with the part they share.  The key definitions of this file are therefore (all over a fixed base (pre)category [C]):  

- _object-extension structures_, [obj_ext_structure], the common core of CwF’s and split type-categories;
- (_functional) term structures_, [term_fun_structure], the rest of the structure of a CwF on [C];
- _cwf-structures_, [cwf_structure], the full structure of a CwF on a precategory [C]; 
- _CwF’s_, [cwf]; 
- _q-morphism structures_, [qq_morphism_structure], for rest of the structure of a split type-category on [C];
- _split type-cat structures_, [split_typecat_structure], the full structure of a split type-category on [C].
- _split type-categories_, [split_typecat].

NB: we follow the convention that _category_ does not include an assumption of saturation/univalence, i.e. means what is sometimes called _precategory_.
*)



Require Import UniMath.Foundations.Sets.
Require Import TypeTheory.Auxiliary.CategoryTheoryImports.

Require Import TypeTheory.Auxiliary.Auxiliary.
Require Import TypeTheory.Auxiliary.UnicodeNotations.

Set Automatic Introduction.

(** * Object-extension structures 

We start by fixing the common core of families structures and split type-category structures: an _object-extension structure_, a presheaf of “types” together with “extension” and “dependent projection” operations.

Components of [X : obj_ext_structure C]:

- [TY Γ : hSet]
- [comp_ext X Γ A : C].  Notation: [Γ ◂ A]
- [π A : Γ ◂ A -->  A ⟧ *)
Section Obj_Ext_Structures.

Context {C : precategory}.

Definition obj_ext_structure : UU
  := ∑ Ty : preShv C,
        ∏ (Γ : C) (A : (Ty : functor _ _ ) Γ : hSet ), ∑ (ΓA : C), ΓA --> Γ.

Definition TY (X : obj_ext_structure) : preShv _ := pr1 X.
Local Notation "'Ty'" := (fun X Γ => (TY X : functor _ _) Γ : hSet) (at level 10).

Definition comp_ext (X : obj_ext_structure) Γ A : C := pr1 (pr2 X Γ A).
Local Notation "Γ ◂ A" := (comp_ext _ Γ A) (at level 30).

Definition π {X : obj_ext_structure} {Γ} A : Γ ◂ A --> Γ := pr2 (pr2 X _ A).

(** ** Lemmas: extensions by equal types *)

(* One frequently needs to deal with isomorphisms between context extensions [Γ ◂ A ≃ Γ ◂ A'] induced by type equalities [e : A = A']; so we collect lemmas for them, and notate them concisely as [Δ e]. *)

Section Comp_Ext_Compare.

Definition comp_ext_compare {X : obj_ext_structure}
    {Γ : C} {A A' : Ty X Γ} (e : A = A')
  : Γ ◂ A --> Γ ◂ A'
:= idtoiso (maponpaths (comp_ext X Γ) e).

Lemma comp_ext_compare_id {X : obj_ext_structure}
    {Γ : C} (A : Ty X Γ)
  : comp_ext_compare (idpath A) = identity (Γ ◂ A).
Proof.
  apply idpath.
Qed.

Lemma comp_ext_compare_id_general {X : obj_ext_structure}
    {Γ : C} {A : Ty X Γ} (e : A = A)
  : comp_ext_compare e = identity (Γ ◂ A).
Proof.
  apply @pathscomp0 with (comp_ext_compare (idpath _)).
  apply maponpaths, setproperty.
  apply idpath.
Qed.

Lemma comp_ext_compare_comp {X : obj_ext_structure}
    {Γ : C} {A A' A'' : Ty X Γ} (e : A = A') (e' : A' = A'')
  : comp_ext_compare (e @ e') = comp_ext_compare e ;; comp_ext_compare e'.
Proof.
  apply pathsinv0.
  etrans. apply idtoiso_concat_pr. 
  unfold comp_ext_compare. apply maponpaths, maponpaths.
  apply pathsinv0, maponpathscomp0. 
Qed.

(* TODO: any reason why comp_ext_compare is the morphism not just the iso?? *)
Lemma comp_ext_compare_inv {X : obj_ext_structure}
    {Γ : C} {A A' : Ty X Γ : hSet} (e : A = A')
  : comp_ext_compare (!e) = inv_from_iso (idtoiso (maponpaths (comp_ext X Γ) e)).
Proof.
  destruct e; apply idpath.
Defined.

Lemma comp_ext_compare_π {X : obj_ext_structure}
    {Γ : C} {A A' : Ty X Γ} (e : A = A')
  : comp_ext_compare e ;; π A' = π A.
Proof.
  destruct e; cbn. apply id_left.
Qed.

Lemma comp_ext_compare_comp_general {X : obj_ext_structure}
    {Γ : C} {A A' A'' : Ty X Γ} (e : A = A') (e' : A' = A'') (e'' : A = A'')
  : comp_ext_compare e'' = comp_ext_compare e ;; comp_ext_compare e'.
Proof.
  refine (_ @ comp_ext_compare_comp _ _).
  apply maponpaths, setproperty.
Qed.

End Comp_Ext_Compare.

End Obj_Ext_Structures.

Arguments obj_ext_structure _ : clear implicits.

Local Notation "Γ ◂ A" := (comp_ext _ Γ A) (at level 30).
Local Notation "'Ty'" := (fun X Γ => (TY X : functor _ _) Γ : hSet) (at level 10).

(** The definitions of term structures and split type-category structures will all be relative to a fixed base category and object-extension structure. *)

Section Families_Structures.

Context {C : category} {X : obj_ext_structure C}.

(** * Families structures 

We now define the extra structure, over an object-extension structure, which constitutes a _category with families_ in the sense of Fiore a reformulation of Dybjer’s original definition, replacing the functor [C --> FAM] with an arrow in [preShv C].

We call this _term structure_, or a _functional_ term structure [term_fun] when necessary to disambiguate from Dybjer-style _familial_ term structures.

Components of [Y : term_fun_structure X]:

- [TM Y : preShv C] 
- [pp Y : TM Y --> TY X]
- [Q Y A :  Yo (Γ ◂ A) --> TM Y]
- [Q_pp Y A : #Yo (π A) ;; yy A = Q Y A ;; pp Y]
- [isPullback_Q_pp Y A : isPullback _ _ _ _ (Q_pp Y A)]

 See: Marcelo Fiore, slides 32–34 of _Discrete Generalised Polynomial Functors_ , from talk at ICALP 2012,
  #(<a href="http://www.cl.cam.ac.uk/~mpf23/talks/ICALP2012.pdf">link</a>)#
  and comments in file [CwF_def].

*)

Local Notation "A [ f ]" := (# (TY X : functor _ _ ) f A) (at level 4).

Definition term_fun_structure_data : UU
  := ∑ TM : preShv C, 
        (TM --> TY X)
        × (∏ (Γ : C) (A : Ty X Γ), (TM : functor _ _) (Γ ◂ A) : hSet).

Definition TM (Y : term_fun_structure_data) : preShv C := pr1 Y.
Local Notation "'Tm'" := (fun Y Γ => (TM Y : functor _ _) Γ : hSet) (at level 10).

Definition pp Y : TM Y --> TY X := pr1 (pr2 Y).

Definition te Y {Γ:C} A : Tm Y (Γ ◂ A)
  := pr2 (pr2 Y) Γ A.

Definition Q Y {Γ:C} (A:Ty X Γ) : Yo (Γ ◂ A) --> TM Y
  := yy (te Y A).

Lemma comp_ext_compare_Q Y Γ (A A' : Ty X Γ) (e : A = A') : 
  #Yo (comp_ext_compare e) ;; Q Y A' = Q Y A . 
Proof.
  induction e. 
  etrans. apply cancel_postcomposition. apply functor_id.
  apply id_left.
Qed.

(* Note: essentially a duplicate of [TypeTheory.ALV1.CwF_def.cwf_square_comm].
  However, using that here would add [CwF_def] as a dependency for this and all subsequent files, which is otherwise not needed; so we repeat the (short) proof to avoid the dependency.  *)
Lemma term_fun_str_square_comm {Y : term_fun_structure_data}
    {Γ : C} {A : Ty X Γ}
    (e : (pp Y : nat_trans _ _) _ (te Y A) = A [ π A ])
  : #Yo (π A) ;; yy A = Q Y A ;; pp Y.
Proof.
  apply pathsinv0.
  etrans. Focus 2. apply yy_natural.
  etrans. apply yy_comp_nat_trans.
  apply maponpaths, e.
Qed.

Definition term_fun_structure_axioms (Y : term_fun_structure_data) :=
  ∏ Γ (A : Ty X Γ), 
        ∑ (e : (pp Y : nat_trans _ _) _ (te Y A) = A [ π A ]),
          isPullback _ _ _ _ (term_fun_str_square_comm e).

Lemma isaprop_term_fun_structure_axioms Y
  : isaprop (term_fun_structure_axioms Y).
Proof.
  do 2 (apply impred; intro).
  apply isofhleveltotal2.
  - apply setproperty.
  - intro. apply isaprop_isPullback.
Qed.

Definition term_fun_structure : UU :=
  ∑ Y : term_fun_structure_data, term_fun_structure_axioms Y.
Coercion term_fun_data_from_term_fun (Y : term_fun_structure) : _ := pr1 Y.


Definition pp_te (Y : term_fun_structure) {Γ} (A : Ty X Γ)
  : (pp Y : nat_trans _ _) _ (te Y A)
    = A [ π A ]
:= pr1 (pr2 Y _ A).

Definition Q_pp (Y : term_fun_structure) {Γ} (A : Ty X Γ) 
  : #Yo (π A) ;; yy A = Q Y A ;; pp Y
:= term_fun_str_square_comm (pp_te Y A).

(* TODO: rename this to [Q_pp_Pb], or [qq_π_Pb] to [isPullback_qq_π]? *)
Definition isPullback_Q_pp (Y : term_fun_structure) {Γ} (A : Ty X Γ)
  : isPullback _ _ _ _ (Q_pp Y A)
:= pr2 (pr2 Y _ _ ).

(* TODO: look for places these three lemmas can be used to simplify proofs *) 
Definition Q_pp_Pb_pointwise (Y : term_fun_structure) (Γ' Γ : C) (A : Ty X Γ)
  := isPullback_preShv_to_pointwise (homset_property _) (isPullback_Q_pp Y A) Γ'.

Definition Q_pp_Pb_univprop (Y : term_fun_structure) (Γ' Γ : C) (A : Ty X Γ)
  := pullback_HSET_univprop_elements _ (Q_pp_Pb_pointwise Y Γ' Γ A).

Definition Q_pp_Pb_unique (Y : term_fun_structure) (Γ' Γ : C) (A : Ty X Γ)
  := pullback_HSET_elements_unique (Q_pp_Pb_pointwise Y Γ' Γ A).

(** ** Terms as sections *)

(* In any term structure, “terms” correspond to sections of dependent projections.  For now, we do not need this full isomorphism, but we construct the beginning of the correspondence. *)
  
Lemma term_to_section_aux {Y : term_fun_structure} {Γ:C} (t : Tm Y Γ) 
  (A := (pp Y : nat_trans _ _) _ t)
  : iscontr
    (∑ (f : Γ --> Γ ◂ A), 
         f ;; π _ = identity Γ
       × (Q Y A : nat_trans _ _) Γ f = t).
Proof.
  set (Pb := isPullback_preShv_to_pointwise (homset_property _) (isPullback_Q_pp Y A) Γ).
  simpl in Pb.
  apply (pullback_HSET_univprop_elements _ Pb).
  exact (toforallpaths _ _ _ (functor_id (TY X) _) A).
Qed.

Lemma term_to_section {Y : term_fun_structure} {Γ:C} (t : Tm Y Γ) 
  (A := (pp Y : nat_trans _ _) _ t)
  : ∑ (f : Γ --> Γ ◂ A), (f ;; π _ = identity Γ).
Proof.
  set (sectionplus := iscontrpr1 (term_to_section_aux t)).
  exists (pr1 sectionplus).
  exact (pr1 (pr2 sectionplus)).
Defined.

(* TODO: unify with lemmas following [bar] in […_Equivalence]? *)
Lemma term_to_section_recover {Y : term_fun_structure}
  {Γ:C} (t : Tm Y Γ) (A := (pp Y : nat_trans _ _) _ t)
  : (Q Y A : nat_trans _ _) _ (pr1 (term_to_section t)) = t.
Proof.
  exact (pr2 (pr2 (iscontrpr1 (term_to_section_aux t)))).
Qed.

Lemma Q_comp_ext_compare {Y : term_fun_structure}
    {Γ Γ':C} {A A' : Ty X Γ} (e : A = A') (t : Γ' --> Γ ◂ A)
  : (Q Y A' : nat_trans _ _) _ (t ;; comp_ext_compare e)
  = (Q Y A : nat_trans _ _) _ t.
Proof.
  destruct e. apply maponpaths, id_right.
Qed.

End Families_Structures.

Section qq_Morphism_Structures.

(* NOTE: most of this section does not require the [homset_property] for [C]. If the few lemmas that do require it were moved out of the section, e.g. [isaprop_qq_morphism_axioms], then would could take [C] as just a [precategory] here. Perhaps worth doing so?

(Another alternative would be adding an extra argument of type [has_homsets C] to [isaprop_qq_morphism_axioms], but that’s less convenient for later use than just having [C] be a [category] in those lemmas.) *)

Context {C : category} {X : obj_ext_structure C}.

(** * q-morphism structures, split type-categories

On the other hand, a _q-morphism structure_ (over an object-extension structure) is what is required to constitute a _split type-category_.

Up to ordering/groupoing of the components, these are essentially the _type-categories_ of Andy Pitts, _Categorical Logic_, 2000, Def. 6.3.3 #(<a href="http://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-367.html">link</a>)# (which in turn were a reformulation of Cartmell’s _categories with attributes_).

Our terminology follows van den Berg and Garner, _Topological and simplicial models_, Def 2.2.1 #(<a href="http://arxiv.org/abs/1007.4638">arXiv</a>)# 
in calling this notion a _split_ type-category, and reserving _type-category_ (unqualified) for the weaker version without hSet/splitness assumptions.  We formalise non-split type-categories elsewhere, since they do not extend object-extension structures.

Beyond the object extension structure, the only further data in a split type-category is the morphisms customarily denoted [qq f A : Γ ◂ A --> Γ] (satisfying certain axioms).  We therefore call this data a _q_-morphism structure.

Components of [Z : qq_morphism_structure X]:

- [qq Z f A : Γ' ◂ A[f] --> Γ ◂ A]
- [qq_π Z f A : qq Z f A ;; π A = π _ ;; f]
- [qq_π_Pb Z f A : isPullback _ _ _ _ (!qq_π Z f A)]
- [qq_id], [qq_comp]: functoriality for [qq]
*)

Local Notation "A [ f ]" := (# (TY X : functor _ _ ) f A) (at level 4).

Definition qq_morphism_data : UU :=
  ∑ q : ∏ {Γ Γ'} (f : C⟦Γ', Γ⟧) (A : (TY X:functor _ _ ) Γ : hSet), 
           C ⟦Γ' ◂ A [ f ], Γ ◂ A⟧, 
    (∏ Γ Γ' (f : C⟦Γ', Γ⟧) (A : (TY X:functor _ _ ) Γ : hSet), 
        ∑ e : q f A ;; π _ = π _ ;; f , isPullback _ _ _ _ (!e)).

Definition qq (Z : qq_morphism_data) {Γ Γ'} (f : C ⟦Γ', Γ⟧)
              (A : (TY X:functor _ _ ) Γ : hSet) 
  : C ⟦Γ' ◂ A [ f ], Γ ◂ A⟧
:= pr1 Z _ _ f A.

(* TODO: consider changing the direction of this equality? *)
Lemma qq_π (Z : qq_morphism_data) {Γ Γ'} (f : Γ' --> Γ) (A : _ )
  : qq Z f A ;; π A = π _ ;; f.
Proof.
  exact (pr1 (pr2 Z _ _ f A)).
Qed.

Lemma qq_π_Pb (Z : qq_morphism_data) {Γ Γ'} (f : Γ' --> Γ) (A : _ ) : isPullback _ _ _ _ (!qq_π Z f A).
Proof.
  exact (pr2 (pr2 Z _ _ f A)).
Qed.

Lemma comp_ext_compare_qq (Z : qq_morphism_data)
  {Γ Γ'} {f f' : C ⟦Γ', Γ⟧} (e : f = f') (A : Ty X Γ) 
  : comp_ext_compare (maponpaths (λ k : C⟦Γ', Γ⟧, A [k]) e) ;; qq Z f' A
  = qq Z f A.
Proof.
  induction e.
  apply id_left.
Qed.

Lemma comp_ext_compare_qq_general (Z : qq_morphism_data)
  {Γ Γ' : C} {f f' : Γ' --> Γ} (e : f = f')
  {A : Ty X Γ} (eA : A[f] = A[f']) 
  : comp_ext_compare eA ;; qq Z f' A
  = qq Z f A.
Proof.
  refine (_ @ comp_ext_compare_qq _ e A).
  apply maponpaths_2, maponpaths, setproperty.
Qed.

Definition qq_morphism_axioms (Z : qq_morphism_data) : UU
  := 
    (∏ Γ A,
    qq Z (identity Γ) A
    = comp_ext_compare (toforallpaths _ _ _ (functor_id (TY X) _ ) _ ))
  ×
    (∏ Γ Γ' Γ'' (f : C⟦Γ', Γ⟧) (g : C ⟦Γ'', Γ'⟧) (A : (TY X:functor _ _ ) Γ : hSet),
    qq Z (g ;; f) A
    = comp_ext_compare
           (toforallpaths _ _ _ (functor_comp (TY X) _ _) A)
      ;; qq Z g (A [f]) 
      ;; qq Z f A).

Definition qq_morphism_structure : UU
  := ∑ Z : qq_morphism_data,
           qq_morphism_axioms Z.

Definition qq_morphism_data_from_structure :
   qq_morphism_structure -> qq_morphism_data := pr1.
Coercion qq_morphism_data_from_structure :
   qq_morphism_structure >-> qq_morphism_data.

Definition qq_id (Z : qq_morphism_structure)
    {Γ} (A : Ty X Γ)
  : qq Z (identity Γ) A
  = comp_ext_compare (toforallpaths _ _ _ (functor_id (TY X) _ ) _ )
:= pr1 (pr2 Z) _ _.

Definition qq_comp (Z : qq_morphism_structure)
    {Γ Γ' Γ'' : C}
    (f : C ⟦ Γ', Γ ⟧) (g : C ⟦ Γ'', Γ' ⟧) (A : Ty X Γ)
  : qq Z (g ;; f) A
  = comp_ext_compare (toforallpaths _ _ _ (functor_comp (TY X) _ _) A)
    ;; qq Z g (A [f]) ;; qq Z f A
:= pr2 (pr2 Z) _ _ _ _ _ _.

Lemma isaprop_qq_morphism_axioms (Z : qq_morphism_data)
  : isaprop (qq_morphism_axioms Z).
Proof.
  apply isofhleveldirprod.
  - do 2 (apply impred; intro).
    apply homset_property.
  - do 6 (apply impred; intro).
    apply homset_property.    
Qed.

(* Since [Ty X] is always an hset, the splitness properties hold with any path in place of the canonical ones. This is sometimes handy, as one may want to opacify the canonical equalities in examples. *)
Lemma qq_comp_general (Z : qq_morphism_structure)
  {Γ Γ' Γ'' : C}
  {f : C ⟦ Γ', Γ ⟧} {g : C ⟦ Γ'', Γ' ⟧} {A : Ty X Γ}
  (p : A [g ;; f]
       = # (TY X : functor _ _) g (# (TY X : functor _ _) f A)) 
: qq Z (g ;; f) A
  = comp_ext_compare p ;; qq Z g (A [f]) ;; qq Z f A.
Proof.
  eapply pathscomp0. apply qq_comp.
  repeat apply (maponpaths (fun h => h ;; _)).
  repeat apply maponpaths. apply uip. apply setproperty.
Qed.

End qq_Morphism_Structures.

Arguments term_fun_structure_data _ _ : clear implicits.
Arguments term_fun_structure_axioms _ _ _ : clear implicits.
Arguments term_fun_structure _ _ : clear implicits.
Arguments qq_morphism_data [_] _ .
Arguments qq_morphism_structure [_] _ .

(** * CwF’s, split type-categories *)

(** Here, we assemble the components above (object-extension structures, term-structures, and _q_-morphism structures) into versions of the definitions of CwF’s and split type-categories.

These are reassociated compared to the canonical definitions; equivalences between these and the canonical ones are provided in [CwF_Defs_Equiv.v] and [TypeCat_Reassoc.v] respectively. *)
(* TODO: rename one of those files, for consistency (and make sure README up-to-date on filenames). *)

Definition cwf'_structure (C : category) : UU 
:= ∑ X : obj_ext_structure C, term_fun_structure C X.

Coercion obj_ext_structure_of_cwf'_structure {C : category}
:= pr1 : cwf'_structure C -> obj_ext_structure C.

Coercion term_fun_structure_of_cwf'_structure {C : category}
:= pr2 : forall XY : cwf'_structure C, term_fun_structure C XY.

Definition cwf' : UU
:= ∑ C : category, cwf'_structure C.

Coercion precategory_of_cwf' := pr1 : cwf' -> category.

Coercion cwf'_structure_of_cwf' := pr2 : forall C : cwf', cwf'_structure C.

Definition split_typecat'_structure (C : category) : UU 
:= ∑ X : obj_ext_structure C, qq_morphism_structure X.

Coercion obj_ext_structure_of_split_typecat'_structure {C : category}
:= pr1 : split_typecat'_structure C -> obj_ext_structure C.

Coercion qq_morphism_structure_of_split_typecat'_structure {C : category}
:= pr2 : forall XY : split_typecat'_structure C, qq_morphism_structure XY.

Definition split_typecat' : UU
  := ∑ C : category, split_typecat'_structure C.

Coercion precategory_of_split_typecat'
:= pr1 : split_typecat' -> category.

Coercion split_typecat'_structure_of_split_typecat'
:= pr2 : forall C : split_typecat', split_typecat'_structure C.

