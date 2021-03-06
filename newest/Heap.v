Require Export List.
Export ListNotations.
Require Export SpecLib. 
Require Export AST. 
Require Import Coq.Logic.ProofIrrelevance.
Require Import Coq.Sets.Ensembles. 
Require Import Coq.Sets.Powerset_facts. 

Definition rawHeap (T:Type) := list (id * T). 

Inductive unique (T:Type) (seen:Ensemble id) : rawHeap T -> Prop :=
|consUnique : forall m H v, ~ In id seen m -> unique T (Add id seen m) H ->
                            unique T seen ((m, v)::H)
|nilUnique : unique T seen nil. 

Inductive heap (T:Type) : Type := 
|heap_ : forall h, unique T (Empty_set id) h -> heap T. 

Definition empty (T:Type) : heap T := heap_ T (@nil (id * T)) (nilUnique T (Empty_set id)). 

Fixpoint raw_heap_lookup {T : Type} (i : id) (h : rawHeap T) := 
  match h with
    |(n, v)::h' => if beq_nat i n then Some v else raw_heap_lookup i h'
    |nil => None
  end.

Definition heap_lookup {T:Type} (i:id) (h:heap T) :=
  match h with
      |heap_ h prf => raw_heap_lookup i h
  end. 
 
Definition raw_extend {T : Type} (x:id) v (heap : rawHeap T) := ((x, v)::heap). 
 
Theorem AddUnique : forall T x H S, 
                 raw_heap_lookup x H = None ->
                 unique T S H -> unique T (Add id S x) H. 
Proof.
  induction H; intros. 
  {constructor. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. inv H0. inv H1. 
   constructor. intros c. inv c. contradiction. inv H1. apply beq_nat_false in eq. 
   apply eq. auto. rewrite Add_commutative. apply IHlist; auto. }
Qed. 
  
Theorem extendPreservesUniqueness : forall T h v x prf, 
                             heap_lookup x (heap_ T h prf) = None -> 
                             unique T (Empty_set id) h ->
                             unique T (Empty_set id) (raw_extend x v h). 
Proof.
  induction h; intros. 
  {inv H0. inv H. constructor. intros c. inv c. constructor. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. inv H. inv H0. 
   constructor. intros c. inv c. constructor. intros c. inv c. 
   inv H0. inv H0. apply beq_nat_false in eq. apply eq. auto. 
   rewrite Add_commutative. apply AddUnique; auto. }
Qed. 

Definition getRawHeap {T:Type} (h:heap T) := 
  match h with
      heap_ h p => h
  end. 

Theorem lookupImpliesRawLookup : forall T x (H:heap T) v, 
                                   heap_lookup x H = v -> 
                                   raw_heap_lookup x (getRawHeap H) = v. 
Proof.
  intros. destruct H. simpl in *. auto. 
Qed. 

Definition extend {T:Type} (x:id) (v:T) (h:heap T) (p:heap_lookup x h=None) := 
  match h as h0 return (heap_lookup x h0 = None -> heap T) with
    | heap_ h0 u =>
      fun p0 : heap_lookup x (heap_ T h0 u) = None =>
        (fun p1 : unique T (Empty_set id) (raw_extend x v h0) =>
           heap_ T (raw_extend x v h0) p1)
          (extendPreservesUniqueness T h0 v x u p0 u)
  end p.

(*Test case
Theorem empty_unique : unique nat (Empty_set id) nil. 
  intros. constructor. Qed. 

Definition h := heap_ nat nil empty_unique. 

Theorem lookup1 : heap_lookup 1 h = None. 
Proof. simpl. reflexivity. Qed. 

Eval compute in extend 1 2 h lookup1. 
*)

Fixpoint raw_replace {T:Type} i v (h : rawHeap T) :=
  match h with
      |(i', v') :: h' => if beq_nat i i' 
                         then (i, v) :: h' 
                         else (i', v') :: raw_replace i v h'
      |nil => nil
  end.

Theorem replacePreservesUniqueness : forall T h S v x, 
                                         unique T S h ->
                                         unique T S (raw_replace x v h). 
Proof.
  induction h; intros.
  {simpl. constructor. }
  {inv H. simpl in *. destruct (beq_nat x m) eqn:eq. 
   {apply beq_nat_true in eq; subst. constructor. auto. assumption. }
   {constructor. auto. apply IHh. auto. }
  }
Qed. 

Definition replace {T:Type} i v (h:heap T) :=
  match h with
      |heap_ h' prf => 
       heap_ T (raw_replace i v h') 
             (replacePreservesUniqueness T h' (Empty_set id) v i prf)
  end. 

Fixpoint raw_remove {T:Type} (h : rawHeap T) x :=
  match h with
      |(x', v')::h' => if beq_nat x x' then h' else (x', v')::raw_remove h' x
      |nil => nil
  end.


Theorem uniqueSubset : forall T h S S',
                         unique T S h -> Included id S' S ->
                         unique T S' h. 
Proof.
  induction h; intros. 
  {constructor. }
  {inv H. constructor. unfold Included in H0. intros c. apply H0 in c. 
   contradiction. eapply IHh; eauto. unfold Included in *. intros. 
   inv H. apply H0 in H1. constructor. auto. inv H1. 
   apply Union_intror. constructor. }
Qed. 

Theorem removePreservesUniqueness : forall T h S x, 
                                      unique T S h ->
                                      unique T S (raw_remove h x). 
Proof.
  induction h; intros. 
  {simpl. auto. }
  {simpl. destruct a. destruct (beq_nat x i) eqn:eq. 
   {inv H. eapply uniqueSubset. eauto. unfold Included. intros. 
    constructor. auto. }
   {inv H. constructor. auto. eapply IHh. auto. }
  }
Qed. 

Definition remove {T:Type} (h:heap T) x :=
  match h with
    |heap_ h' prf => 
     heap_ T (raw_remove h' x) (removePreservesUniqueness T h' (Empty_set id)x prf)
  end. 

Theorem raw_heapUpdateNeq : forall (T:Type) h i (v v' : T),
                          raw_heap_lookup i h = Some v -> 
                          v <> v' -> h <> raw_replace i v' h. 
Proof.
  intros. intros c. induction h. 
  {inv H. }
  {simpl in *. destruct a. destruct (beq_nat i i0) eqn:eq. 
   {inv H. inv c. apply H0. auto. }
   {inversion c. apply IHh. auto. auto. }
  }
Qed. 

Theorem heapUpdateNeq : forall (T:Type) h i (v v' : T),
                          heap_lookup i h = Some v ->
                          v <> v' -> h <> replace i v' h. 
Proof.
  intros. intros c. destruct h. simpl in *.
  eapply raw_heapUpdateNeq in H; eauto. inversion c. contradiction. 
Qed. 

Theorem raw_HeapLookupReplace : forall (T:Type) x (h:rawHeap T) v v', 
                              raw_heap_lookup x h = Some v' ->
                              raw_heap_lookup x (raw_replace x v h) = Some v. 
Proof.
  intros. induction h. 
  {inversion H. }
  {simpl. destruct a. destruct (beq_nat x i) eqn:eq. 
   {simpl. rewrite <- beq_nat_refl. reflexivity. }
   {simpl in *.  rewrite eq. rewrite eq in H. apply IHh in H. assumption. }
  }
Qed. 

Theorem HeapLookupReplace : forall (T:Type) x (h:heap T) v v', 
                              heap_lookup x h = Some v' ->
                              heap_lookup x (replace x v h) = Some v. 
Proof.
  intros. destruct h. simpl in *. eapply raw_HeapLookupReplace. eauto. 
Qed. 

Theorem lookupExtend : forall (T:Type) x H (v:T) p, 
                         heap_lookup x (extend x v H p) = Some v. 
Proof. 
  destruct H. intros. simpl in *. rewrite <- beq_nat_refl. auto. 
Qed. 

Theorem rawHeapsEq : forall T H H' prf prf',  H = H' -> heap_ T H prf = heap_ T H' prf'. 
Proof.
  intros. subst. assert(prf=prf'). apply proof_irrelevance. subst. auto.
Qed. 

Theorem raw_replaceOverwrite : forall (T:Type) x (v v':T) H, 
                             raw_replace x v (raw_replace x v' H) = raw_replace x v H. 
Proof. 
  induction H; intros. 
  {auto. }
  {simpl. destruct a. destruct (beq_nat x i) eqn:eq. 
   {simpl. rewrite <- beq_nat_refl. auto. }
   {simpl. rewrite eq. rewrite IHlist. auto. }
  }
Qed. 

Theorem replaceOverwrite : forall (T:Type) x (v v':T) H,
                             replace x v (replace x v' H) = replace x v H. 
Proof.
  intros. destruct H. simpl in *. eapply rawHeapsEq. apply raw_replaceOverwrite. 
Qed. 

Theorem raw_lookupReplaceSwitch : forall T x x' (v v':T) H,
                                x<>x' -> raw_replace x v (raw_replace x' v' H) =
                                         raw_replace x' v' (raw_replace x v H).
Proof.
  induction H. 
  {auto. }
  {intros. simpl. destruct a. destruct(beq_nat x' i) eqn:eq1. 
   {destruct(beq_nat x i) eqn:eq2. 
    {apply beq_nat_true in eq1. apply beq_nat_true in eq2. subst. exfalso; apply H0; auto. }
    {simpl. apply beq_nat_false_iff in H0. rewrite H0. rewrite eq1. auto. }
   }
   {destruct (beq_nat x i) eqn:eq2. 
    {simpl. rewrite eq2. apply beq_nat_false_iff in H0. destruct (beq_nat x' x) eqn:eq3; auto. 
     apply beq_nat_true in eq3. subst. apply beq_nat_false in H0. exfalso. apply H0; auto. }
    {simpl. rewrite eq1. rewrite eq2. rewrite IHlist. auto. assumption. }
   }
  }
Qed.  

Theorem lookupReplaceSwitch : forall T x x' (v v':T) H,
                                x<>x' -> replace x v (replace x' v' H) = replace x' v' (replace x v H).
Proof.
  intros. destruct H; simpl in *. apply rawHeapsEq. apply raw_lookupReplaceSwitch; auto. 
Qed. 

Theorem lookupExtendNeq : forall (T:Type) x H x' v (v':T) p, 
                            heap_lookup x H = v -> x <> x' -> 
                            heap_lookup x (extend x' v' H p) = v.
Proof.
  intros. destruct H; simpl in *. apply beq_nat_false_iff in H1. rewrite H1. auto. 
Qed. 

Axiom heapExtensionality : forall (T:Type) (H H' : rawHeap T),
                             (forall x, raw_heap_lookup x H = raw_heap_lookup x H') -> H = H'. 


Theorem raw_extendReplaceSwitch : forall (T:Type)x x' (v v':T) H z,
                                x <> x' -> raw_heap_lookup x' H = Some z -> 
                                raw_extend x v (raw_replace x' v' H) = raw_replace x' v' (raw_extend x v H). 
Proof.
  induction H; intros. 
  {inv H0. }
  {simpl in *. destruct a. destruct (beq_nat x' i) eqn:eq1. 
   {inv H1. rewrite <- beq_nat_false_iff in H0. rewrite SfLib.beq_nat_sym in H0. rewrite H0.
    auto. }
   {rewrite <- beq_nat_false_iff in H0. rewrite SfLib.beq_nat_sym in H0. rewrite H0. 
    rewrite H0 in IHlist. unfold raw_extend. auto. }
  }
Qed. 

Theorem extendReplaceSwitch : forall (T:Type)x x' (v v':T) H z p p',
                                x <> x' -> heap_lookup x' H = Some z -> 
                                extend x v (replace x' v' H) p' = replace x' v' (extend x v H p). 
Proof.
  intros. destruct H. apply rawHeapsEq. eapply raw_extendReplaceSwitch; eauto. 
Qed. 

Theorem raw_lookupReplaceNeq : forall (T:Type) H x x'  (v':T),
                             x <> x' -> raw_heap_lookup x (raw_replace x' v' H) = raw_heap_lookup x H. 
Proof.
  induction H; intros. 
  {simpl. auto. }
  {simpl in *. destruct a. destruct (beq_nat x' i) eqn:eq1; destruct (beq_nat x i) eqn:eq2. 
   simpl. apply beq_nat_true in eq1. apply beq_nat_true in eq2. subst. exfalso. apply H0. 
   auto. simpl. rewrite <- beq_nat_false_iff in H0. rewrite H0. auto. simpl. rewrite eq2. 
   auto. simpl. rewrite eq2. auto. }
Qed.

Theorem lookupReplaceNeq : forall (T:Type) H x x' (v':T),
                             x <> x' -> heap_lookup x (replace x' v' H) = heap_lookup x H. 
Proof.
  intros. destruct H. simpl. apply raw_lookupReplaceNeq; auto. 
Qed. 

Theorem raw_replaceSame : forall (T:Type) H x (v:T),
                        raw_heap_lookup x H = Some v -> raw_replace x v H = H. 
Proof.
  induction H; intros. 
  {inv H. }
  {simpl in *. destruct a. destruct (beq_nat x i)eqn:eq. 
   {inv H0. apply beq_nat_true in eq. subst. auto. }
   {rewrite IHlist; eauto. }
  }
Qed. 

Theorem replaceSame : forall (T: Type) H x (v:T),
                        heap_lookup x H = Some v -> replace x v H = H. 
Proof.
  intros. destruct H. simpl. apply rawHeapsEq. eapply raw_replaceSame; eauto. 
Qed. 

Theorem extendExtendSwitch : forall (T:Type) x x' (v v':T) H p p' p'' p''', 
                               extend x v (extend x' v' H p) p' = 
                               extend x' v' (extend x v H p'') p'''. 
Proof.
  intros. destruct H. simpl in *. eapply rawHeapsEq. destruct (beq_nat x x') eqn:eq. 
  inv p'. unfold raw_extend. apply heapExtensionality. intros. 
  simpl. destruct (beq_nat x0 x) eqn:eq1. 
  {destruct (beq_nat x0 x') eqn:eq2. 
   {apply beq_nat_true in eq1. apply beq_nat_true in eq2. subst. apply beq_nat_false in eq. 
    exfalso. apply eq. auto. }
   {auto. }
  }
  {destruct (beq_nat x0 x') eqn:eq2; auto. }
Qed. 

Theorem replaceExtendOverwrite : forall (T:Type) x H (v v':T) p p',
                                   replace x v (extend x v' H p) = extend x v H p'. 
Proof.
  intros. destruct H. apply rawHeapsEq. unfold raw_extend. simpl. rewrite <- beq_nat_refl. 
  auto. 
Qed. 
