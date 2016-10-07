
(**

 Ahrens, Lumsdaine, Voevodsky, 2015 - 2016

Contents:

- Definition of comprehension structure relative to 
  a functor, see [fcomprehension]
- Proof that [fcomprehension] is a proposition when
  target precategory is univalent, 
  see [isaprop_fcomprehension]
- Definition of a relative universe structure,
  see [relative_universe_structure]
  Definition due to Vladimir Voevodsky
- Transfer of a relative universe structure along
  two functors and a natural isomorphism, 
  see [rel_univ_struct_functor]

*)

Require Import UniMath.Foundations.Basics.Sets.
Require Import TypeTheory.Auxiliary.CategoryTheoryImports.

Require Import TypeTheory.Auxiliary.Auxiliary.
Require Import TypeTheory.Auxiliary.UnicodeNotations.

Set Automatic Introduction.

Local Notation "[ C , D ]" := (functorPrecategory C D).

(** * Relative comprehension structures *)

(** Given a map [ p : Ũ —> U ] in a category [D], and a functor [ F : C —> D ], _a comprehension structure for [p] relative to [F]_ is an operation providing all pullbacks of [p] along morphisms from objects of the form [F X]. *)

Section Relative_Comprehension.

Context {C D : precategory} (J : functor C D).
Context {U tU : D} (p : D ⟦tU, U⟧).

Definition fpullback_data {X : C} (f : D ⟦J X, U⟧) : UU 
  := Σ Xf : C, C⟦Xf, X⟧ × D⟦J Xf, tU⟧.

Definition fpb_obj  {X : C} {f : D⟦J X, U⟧} (T : fpullback_data f) : C := pr1 T.
Definition fp {X : C} {f : D⟦J X, U⟧} (T : fpullback_data f) : C⟦fpb_obj T, X⟧ := pr1 (pr2 T).
Definition fq {X : C} {f : D⟦J X, U⟧} (T : fpullback_data f) : D⟦ J (fpb_obj T), tU⟧ := pr2 (pr2 T).

Definition fpullback_prop {X : C} {f : D ⟦J X, U⟧} (T : fpullback_data f) : UU 
  := Σ (fe : #J(fp T) ;; f = fq T ;; p), isPullback _ _ _ _ fe .

Definition fpullback {X : C} (f : D ⟦J X, U⟧) := 
  Σ T : fpullback_data f, fpullback_prop T.

Coercion fpullback_data_from_fpullback {X : C} {f : D ⟦J X, U⟧} (T : fpullback f) :
   fpullback_data f := pr1 T.

Definition fcomprehension := Π X (f : D⟦J X, U⟧), fpullback f.

(* TODO: add arguments declaration to make [U], [tU] explicit in these defs not depending on [p]. *)
Definition fcomprehension_data := Π X (f : D⟦ J X, U⟧), fpullback_data f.
Definition fcomprehension_prop (Y : fcomprehension_data) :=
          Π X f, fpullback_prop (Y X f). 

(** * An equivalence separating data and properties *)
(** interchanging Σ and Π *)
Definition fcomprehension_weq :
   fcomprehension ≃ Σ Y : fcomprehension_data, fcomprehension_prop Y.
Proof.
  eapply weqcomp. Focus 2.
    set (XR:=@weqforalltototal (ob C)).
    specialize (XR (fun X => Π f : D⟦ J X, U⟧, fpullback_data f)). simpl in XR.
    specialize (XR (fun X pX => Π A, fpullback_prop  (pX  A))).
    apply XR.
  apply weqonsecfibers.
  intro X.
  apply weqforalltototal.
Defined.

End Relative_Comprehension.

(** ** Some lemmas on the hpropness of the  *)

Section Relative_Comprehension_Lemmas.

Context {C : precategory} {D : Precategory} (J : functor C D).
Context {U tU : D} (p : D ⟦tU, U⟧).

Lemma isaprop_fpullback_prop {X : C} {f : D ⟦J X, U⟧} (T : fpullback_data J f)
  : isaprop (fpullback_prop J p T).
Proof.
  apply isofhleveltotal2.
  - apply homset_property.
  - intros. apply isaprop_isPullback.
Qed.


Lemma isaprop_fpullback {X : C} (f : D ⟦J X, U⟧) 
      (is_c : is_category C)
      (HJ : fully_faithful J)
  : isaprop (fpullback J p f).
Proof.
  apply invproofirrelevance.
  intros x x'. apply subtypeEquality.
  - intro t. apply isaprop_fpullback_prop.
  - destruct x as [x H]. 
    destruct x' as [x' H']. cbn.    
    destruct x as [a m].
    destruct x' as [a' m']. cbn in *.
    destruct H as [H isP].
    destruct H' as [H' isP'].
    simple refine (total2_paths _ _ ).
    + unfold fpullback_prop in *.
      set (T1 := mk_Pullback _ _ _ _ _ _ isP).
      set (T2 := mk_Pullback _ _ _ _ _ _ isP').
      set (i := iso_from_Pullback_to_Pullback T1 T2). cbn in i.
      set (i' := invmap (weq_ff_functor_on_iso HJ a a') i ).
      set (TT := isotoid _ is_c i').
      apply TT.
    + cbn.
      set (XT := transportf_dirprod _ (fun a' => C⟦a', X⟧) (fun a' => D⟦J a', tU⟧)).
      cbn in XT.
      set (XT' := XT (tpair _ a m : Σ a : C, C ⟦ a, X ⟧ × D ⟦ J a, tU ⟧ )
                     (tpair _ a' m' : Σ a : C, C ⟦ a, X ⟧ × D ⟦ J a, tU ⟧ )).
      cbn in *.
      match goal with | [ |- transportf _ ?e _ = _ ] => set (TT := e) end.
      rewrite XT'.
      destruct m as [q r].
      destruct m' as [q' r'].
      cbn. 
      apply pathsdirprod.
      * unfold TT.
        rewrite transportf_isotoid.
        cbn.
        unfold precomp_with.
        rewrite id_right.
        rewrite id_right.
        unfold from_Pullback_to_Pullback. cbn.
        apply (invmaponpathsweq (weq_from_fully_faithful HJ _ _ )).
        assert (T:= homotweqinvweq (weq_from_fully_faithful HJ a' a)).
        cbn in *.
        rewrite functor_comp. rewrite T. clear T.
        clear XT' XT. clear TT. 
        assert (X1:= PullbackArrow_PullbackPr1 (mk_Pullback _ _ _ _ _ _ isP)).
        cbn in X1.
        apply X1.
      * unfold TT. clear TT. clear XT' XT.
        match goal with |[|- transportf ?r  _ _ = _ ] => set (P:=r) end.
        set (T:=@functtransportf _ _ (functor_on_objects J) (fun a' => D⟦ a', tU⟧)).
        rewrite T.
        rewrite <- functtransportf.
        etrans. 
          apply (transportf_isotoid_functor).  
        cbn. unfold precomp_with. rewrite id_right. rewrite id_right.
        assert (XX:=homotweqinvweq (weq_from_fully_faithful HJ a' a  )).
        simpl in XX. rewrite XX. simpl. cbn.
        assert (X1:= PullbackArrow_PullbackPr2 (mk_Pullback _ _ _ _ _ _ isP)).
        apply X1.
Qed.

Lemma isaprop_fcomprehension  (is_c : is_category C)(is_d : is_category D) 
    (HJ : fully_faithful J) : isaprop (fcomprehension J p).
Proof.
  do 2 (apply impred; intro).
  apply isaprop_fpullback; assumption.
Qed.  

End Relative_Comprehension_Lemmas.

(** * Relative universe structures *)

(** A _universe relative to a functor_ is just a map in the target category, equipped with a relative comprehension structure. *)

(* TODO: any reason not to call just [relative_universe]? *)
Definition relative_universe_structure {C D : precategory} (J : functor C D) : UU
  := Σ X : mor_total D, fcomprehension J X.

(** ** Transfer of a relative universe structure *)

(** We give conditions under which a relative universe for one functor can be transferred to one for another functor. *)

Section Rel_Univ_Structure_Transfer.

Context
   {C : precategory} {D : Precategory}
   (J : functor C D)
   (RUJ : relative_universe_structure J)

   {C' : precategory} {D' : Precategory}
   (J' : functor C' D')

   (R : functor C C') (S : functor D D')

   (α : [C, D'] ⟦functor_composite J S , functor_composite R J'⟧)
   (is_iso_α : is_iso α)

   (Res : split_ess_surj R)
   (Sff : fully_faithful S) (* TODO: really only “full” is needed. *)
   (Spb : maps_pb_squares_to_pb_squares _ _ S).


Let αiso := isopair α is_iso_α.
Let α' := inv_from_iso αiso. 
Let α'_α := nat_trans_eq_pointwise (iso_after_iso_inv αiso).

Local Definition α'iso : forall X, is_iso (pr1 α' X).
Proof.
  intros.
  apply is_functor_iso_pointwise_if_iso.
  apply is_iso_inv_from_iso.
Qed.

Local Notation tU := (source (pr1 RUJ)).
Local Notation U :=  (target (pr1 RUJ)).
Local Notation pp := (morphism_from_total (pr1 RUJ)).

Definition fcomprehension_induced
  :  fcomprehension J' (# S (pr1 RUJ)).
Proof.
  cbn in α, α', α'_α.
  intros X' g.
  set (Xi := Res X'); destruct Xi as [X i]; clear Res.
  set (f' := (α X ;; #J' i ;; g) : D' ⟦ S (J X), S U ⟧).
  set (f := invmap (weq_from_fully_faithful Sff _ _ ) f');
  set (e_Sf_f' := homotweqinvweq (weq_from_fully_faithful Sff (J X) U) f'
    : #S f = f');
    clearbody e_Sf_f' f; clear Sff.
  set (Xf :=  (pr2 RUJ) _ f); clearbody Xf.
  destruct Xf as [H A].
  destruct H as [Xf [p q]].
  destruct A as [e isPb]. cbn in e, isPb.
  assert (Sfp := Spb _ _ _ _ _ _ _ _ _ isPb); clear Spb.
  set (HSfp := functor_on_square D D' S e) in *; clearbody HSfp.
  (* TODO: most from here could be abstracted as a general lemma about transfer of pullbacks along isomorphisms, generalising [isPullback_iso_of_morphisms]. *) 
  simple refine (tpair _ _ _ ).
  { exists (R Xf); split.
    - exact (#R p ;; i).
    - refine (identity _ ;; (α' Xf ;; #S q)).
  (* This [identity _] is to make [isPulback_iso_of_morphisms] applicable below. *)
  }
  cbn.
  simple refine (tpair _ _ _ ).
  * cbn.
    rewrite id_left.
    rewrite <- assoc.
    rewrite <- HSfp.
    rewrite assoc.
    assert (Ha' := nat_trans_ax α'); cbn in Ha'.
    rewrite <- Ha'; clear Ha'.
    rewrite e_Sf_f'.
    unfold f'.
    rewrite functor_comp. 
    repeat rewrite <- assoc. apply maponpaths.
    repeat rewrite assoc. apply maponpaths_2.
    cbn in α'_α; rewrite α'_α.
    apply pathsinv0, id_left.
  * cbn.
    match goal with |[|- isPullback _ _ _ _ ?eee] => generalize eee end.
    assert (XXX : g = #J' (inv_from_iso i) ;; α' _ ;; #S f).
    { clear Sfp isPb HSfp.
      rewrite e_Sf_f'.
      unfold f'.
      repeat rewrite assoc.
      match goal with |[ |- _ = ?A1 ;; _ ;; _ ;; ?A2 ;; ?A3] =>
                       pathvia (A1 ;; A2 ;; A3) end.
      - rewrite <- functor_comp.
        rewrite iso_after_iso_inv, functor_id.
        apply pathsinv0, id_left.
      - do 2 apply maponpaths_2.
        rewrite <- assoc.
        rewrite α'_α.
        apply pathsinv0, id_right.
    }
    rewrite XXX; clear XXX.
    rewrite <- assoc.
    intro Hp.
    simple refine
           (isPullback_iso_of_morphisms _ _ _ _ _ _ _ _ _ _ _ _ ).
    - apply (homset_property _ ).
    - apply (#J' (#R p)). 
    - repeat rewrite assoc.
      repeat rewrite assoc in Hp.
      rewrite id_left in Hp.
      rewrite <- Hp.
      rewrite functor_comp.
      do 2 apply cancel_postcomposition.
      rewrite <- assoc.
      rewrite <- functor_comp.
      rewrite iso_inv_after_iso.
      rewrite functor_id. apply pathsinv0, id_right.
    - apply (functor_on_iso_is_iso _ _ _ _ _  (iso_inv_from_iso i)).
    - apply identity_is_iso.
    - rewrite id_left.
      rewrite functor_comp. rewrite <- assoc.
      rewrite <- functor_comp. rewrite iso_inv_after_iso.
      rewrite functor_id. apply id_right.
    - match goal with |[|- isPullback _ _ _ _ ?HHH ]
                       => generalize HHH end.
      clear Hp.
      intro Hp.
      simple refine
             (isPullback_iso_of_morphisms _ _ _ _ _ _ _ _ _ _ _ _ ).
      + apply (homset_property _ ). 
      + cbn. apply (#S (#J p)).
      + apply functor_on_square. assumption.
      + apply α'iso.
      + apply α'iso. 
      + apply (nat_trans_ax α').
      + apply Sfp.
Qed.

Definition transfer_of_rel_univ_struct : relative_universe_structure J'.
Proof.
  mkpair.
  - mkpair.
    + exists (S U).
      exact (S tU).
    + apply (#S pp). 
  - cbn.
    apply fcomprehension_induced.
Defined.

End Rel_Univ_Structure_Transfer.