Require Import SfLib.             
Require Import NonSpec.    
Require Import Spec.  
Require Import Coq.Sets.Ensembles. 
Require Import erasure. 
Require Import AST. 
Require Import hetList. 
Require Import Coq.Program.Equality. 
Require Import unspec. 
Require Import sets.  
Require Import classifiedStep. 
Require Import Coq.Sets.Powerset_facts. 
Require Import Heap. 
Require Import specIndependence. 

Axiom uniqueTP : forall T1 T2 t, tIn (tUnion T1 T2) t -> tIn T1 t -> tIn T2 t -> False. 

Theorem unionEq : forall T1 T2 T2', tUnion T1 T2 = tUnion T1 T2' -> T2 = T2'.  
Proof.
  intros. apply Extensionality_Ensembles. unfold Same_set. unfold Included. split; intros. 
  {apply eqImpliesSameSet in H. unfold Same_set in H. unfold Included in H. inv H. 
   assert(tIn (tUnion T1 T2) x). apply Union_intror. auto. copy H. apply H1 in H.
   inversion H; subst. eapply uniqueTP in H0; eauto. inversion H0. auto. }
  {apply eqImpliesSameSet in H. unfold Same_set in H. unfold Included in H. inv H. 
   assert(tIn (tUnion T1 T2') x). apply Union_intror. auto. copy H. apply H2 in H3. 
   inversion H3; subst. eapply uniqueTP in H0; eauto. inversion H0. auto. }
Qed. 

Hint Constructors Union Couple. 

Ltac eUnspec :=
  match goal with
    | |-spec_multistep ?H ?t ?H' (tUnion ?T' (tSingleton ?t')) =>
        assert(exists t'', unspecThread t' t'') by apply unspecThreadTotal; invertHyp
    | H:spec_multistep ?H ?t ?H' (tUnion ?T' (tSingleton ?t')) |- _ =>
        assert(exists t'', unspecThread t' t'') by apply unspecThreadTotal; invertHyp
  end. 

Ltac rewriteEmpty xs := 
      match xs with
          |HNil => unfold tUnion; try rewrite union_empty_l; try rewrite union_empty_r
          |HCons ?x ?xs' => unfold tUnion in x; try rewrite union_empty_l in x; 
                          try rewrite union_empty_r in x; rewriteEmpty xs'
      end. 

Theorem rollbackWF : forall H H' T TR TR' tidR acts,
                       wellFormed H (tUnion T TR) ->
                       rollback tidR acts H TR H' TR' ->
                       wellFormed H' (tUnion T TR'). 
Admitted. 

Hint Constructors spec_step. 

Theorem UnionEqTID : forall T T' tid s1 s2 M s1' s2' M',
                       tUnion T (tSingleton(tid,s1,s2,M)) = tUnion T' (tSingleton(tid,s1',s2',M')) ->
                       T = T' /\ s1 = s1' /\ s2 = s2' /\ M = M'. 
Proof. 
  intros. unfoldSetEq H. assert(tIn (tUnion T (tSingleton(tid,s1,s2,M)))(tid,s1,s2,M)). 
  apply Union_intror. constructor. copy H.  apply H0 in H. inversion H.  
  {assert(thread_lookup (tUnion T' (tSingleton(tid,s1',s2',M'))) tid (tid,s1,s2,M)). 
   econstructor. econstructor. eauto. auto. 
   assert(thread_lookup (tUnion T' (tSingleton(tid,s1',s2',M'))) tid (tid,s1',s2',M')). 
   econstructor. apply Union_intror. constructor. auto. eapply uniqueThreadPool in H5; eauto. 
   inv H5. repeat constructor; auto. eqSets. 
   {assert(tIn (tUnion T (tSingleton(tid,s1,s2,M))) x). constructor. auto. copy H5. apply H0 in H5. 
    inversion H5; subst. auto. inv H8. exfalso. eapply uniqueTP; eauto. constructor. }
   {assert(tIn (tUnion T' (tSingleton(tid,s1,s2,M))) x). constructor. auto. copy H5. 
    apply H1 in H5. inversion H5; subst. auto. inv H8. exfalso. eapply uniqueTP; eauto. 
    constructor. }
  }
  {subst. inv H3. repeat constructor; auto. eqSets. 
   {assert(tIn (tUnion T (tSingleton(tid,s1,s2,M))) x). constructor. auto. copy H4. apply H0 in H4. 
    inversion H4; subst. auto. inv H6. exfalso. eapply uniqueTP; eauto. constructor. }
   {assert(tIn (tUnion T' (tSingleton(tid,s1,s2,M))) x). constructor. auto. copy H4. 
    apply H1 in H4. inversion H4; subst. auto. inv H6. exfalso. eapply uniqueTP; eauto. 
    constructor. }
  }
Qed. 

Ltac foldTac := fold Add in *; fold tAdd in *; fold tUnion in *; fold tSingleton in *; fold tCouple in *.

Ltac rUnspec := erewrite unspecSingleton; eauto.
Ltac rUnspecIn H := erewrite unspecSingleton in H; eauto.
Ltac rUnspecAll := erewrite unspecSingleton in *; eauto. 



Axiom UnionSingletonEq : forall T T' a b, 
                 tUnion T (tSingleton a) = tUnion T' (tSingleton b) -> 
                 tIn T' a -> T = tUnion (Subtract thread T' a) (tSingleton b).

Ltac invertDecomp :=
  match goal with
    |H:(?a,?b,?c,?d)=(?e,?f,?g,?h) |- _ => inv H
    |H:?x = ?y |- _ => solve[inv H]
    |H:decompose ?M ?E ?e,H':decompose ?M' ?E' ?e' |- _=>
     eapply uniqueCtxtDecomp in H; eauto; invertHyp
  end. 

Axiom UnionSingletonCoupleEq : forall T T' a b c, 
                 tUnion T (tSingleton a) = tUnion T' (tCouple b c) -> 
                 tIn T' a -> T = tUnion (Subtract thread T' a) (tCouple b c).

Axiom CoupleUnionAx : forall T T' t1 t2,
                        tUnion T (tSingleton t1) = tUnion T' (tCouple t1 t2) -> 
                        T = tUnion T' (tSingleton t2).

Ltac actEqTac H :=
  eapply firstActEq in H;[idtac|apply Union_intror; rewrite app_nil_l; constructor|
                          apply Union_intror; constructor]. 

Theorem forkFastForward : forall H T H' T' tid s1' s1'' N M M' M'' n E s2 d,
  decompose M' E (fork M'') -> n = numForks' s2 ->   
  spec_multistep H (tUnion T (tSingleton(tid,unlocked nil, s2, M')))
                 H' (tUnion T' (tCouple(tid,unlocked(s1'++[fAct M' E M'' d n]),s2,M)
                                       (n::tid,locked s1'',nil,N))) ->
  exists H'' T'',
    spec_multistep H (tUnion T (tSingleton(tid,unlocked nil,s2,M')))
                   H'' (tUnion T'' (tCouple(tid,unlocked[fAct M' E M'' d n],s2,fill E (ret unit))
                                          (n::tid,locked nil,nil,M''))) /\
    spec_multistep H'' (tUnion T'' (tCouple(tid,unlocked[fAct M' E M'' d n],s2,fill E (ret unit)) (n::tid,locked nil,nil,M'')))
                   H'(tUnion T' (tCouple(tid,unlocked(s1'++[fAct M' E M'' d n]),s2,M)
                                       (n::tid,locked s1'',nil,N))) /\
    spec_multistep H T H'' T''. 
Proof.
  intros. dependent induction H2. 
  {unfoldTac. rewrite coupleUnion in x. rewrite <- Union_associative in x. 
   rewrite UnionSwap in x. apply UnionEqTID in x. invertHyp. inv H. invertListNeq. }
  {copy x. unfoldSetEq H1. copy H. apply specStepSingleton in H1. invertHyp. 
   assert(tIn (tUnion T0 (tSingleton x0)) x0). apply Union_intror. constructor. 
   apply H3 in H1. inv H1. 
   {eapply IHspec_multistep in H0. Focus 4. auto. Focus 2. auto. Focus 2. 
    apply UnionSingletonEq in x; auto.  
    rewrite x. unfoldTac. rewrite UnionSwap. auto. invertHyp. exists x1. exists x2.
    split; auto. apply pullOut in H5. unfoldTac. rewrite H5. rewrite UnionSwap. 
    econstructor. eapply specStepChangeUnused. eauto. unfoldTac. 
    rewrite <- UnionSwap. eauto. split. auto. copy H5. apply pullOut in H5. 
    rewrite H5. econstructor. eapply specStepChangeUnused. eauto. eauto. }
   {inv H5. apply UnionEqTID in x. invertHyp. clear H1 H5 H7. inversion H; subst. 
    {unfoldTac; invertHyp; invThreadEq.
     inv H5; eapply uniqueCtxtDecomp in H0; eauto; invertHyp; solveByInv. }
    {unfoldTac; invertHyp; invThreadEq. copy d0. eapply uniqueCtxtDecomp in H0; eauto.
     invertHyp. inv H6. exists h'. exists T. split. econstructor. 
     eapply SFork; eauto. simpl. constructor. split. simpl in *. assert(d=d0). 
     apply proof_irrelevance. subst. assumption. constructor. }
    {unfoldTac; invertHyp; invThreadEq. copy d0; eapply uniqueCtxtDecomp in H0; eauto.
     invertHyp. inv H7. }
    {unfoldTac; invertHyp; invThreadEq. copy d0; eapply uniqueCtxtDecomp in H0; eauto.
     invertHyp. inv H7. }
    {unfoldTac; invertHyp; invThreadEq. copy d0; eapply uniqueCtxtDecomp in H0; eauto.
     invertHyp. inv H6. }
    {unfoldTac; invertHyp; invThreadEq. copy d0; eapply uniqueCtxtDecomp in H0; eauto.
     invertHyp. inv H6. }
   }
  }
Qed.

Theorem appCons : forall (T:Type) x (y:T) z,
                    x ++ [y;z] = (x ++ [y]) ++ [z]. 
Proof. 
  intros. rewrite <- app_assoc. simpl. auto. Qed. 

Theorem consedActEq : forall H H' tid s1 s1' a b s2 M M' T T',
                 spec_multistep H T H' T' -> tIn T (tid,unlocked (s1++[a;b]),s2,M) -> 
                 tIn T' (tid,unlocked(s1'++[b]),s2,M') -> exists s, s1' = s ++ [a]. 
Proof.
  intros. genDeps{s1';s1;s2;a;b;M;M';tid}. induction H0; intros. 
  {assert(thread_lookup p2 tid (tid,unlocked(s1++[a;b]),s2,M)). econstructor. eauto. auto. 
   assert(thread_lookup p2 tid (tid,unlocked(s1'++[b]),s2,M')). econstructor. eauto. auto.
   eapply uniqueThreadPool in H; eauto. inv H. destruct s1'. simpl in *. destruct s1; inv H4. 
   destruct s1; inv H5. alignTac a0 s1'. rewrite H in H4. replace [a;b] with ([a]++[b]) in H4; auto. 
   rewrite app_assoc in H4. apply app_inj_tail in H4. invertHyp. apply app_inj_tail in H3. invertHyp. 
   econstructor. rewrite H. eauto. }
  {inv H1. 
   {eapply IHspec_multistep. constructor. eauto. eauto. }
   {copy H. apply specStepSingleton in H. invertHyp. inv H3. inv H1. 
    {unfoldTac; invertHyp. inv H. eapply IHspec_multistep. apply Union_intror. constructor. eauto. }
    {unfoldTac; invertHyp; invThreadEq. eapply IHspec_multistep. apply Union_intror. simpl. 
     rewrite app_comm_cons. constructor. eauto. }
    {unfoldTac; invertHyp. inv H. eapply IHspec_multistep. apply Union_intror. simpl. 
     rewrite app_comm_cons. constructor. eauto. }
    {unfoldTac; invertHyp. inv H. eapply IHspec_multistep. apply Union_intror. simpl. 
     rewrite app_comm_cons. constructor. eauto. }
    {unfoldTac; invertHyp. inv H. eapply IHspec_multistep. apply Union_intror. simpl. 
     rewrite app_comm_cons. constructor. eauto. }
    {unfoldTac; invertHyp. inv H5. eapply IHspec_multistep. apply Union_intror. simpl. 
     rewrite app_comm_cons. constructor. eauto. }
   }
  }
Qed. 

Theorem eraseTrmActTerm : forall x a M M',
                            eraseTrm (x++[a]) M M' ->
                            actionTerm a M'. 
Proof.
  intros. destruct a; inv H; try solve[invertListNeq]; 
  apply lastElementEq in H1; inv H1; constructor. 
Qed. 
 
Theorem forkCatchup' : forall H T H' T' x x0 tid s1' s1'' s2 e1 e1' e2 e2' M' M'' n E d  S S',
    eraseTrm s1' e1' x -> eraseTrm s1'' e2' x0 -> n = numForks' s2 -> S = [] \/ S' = [] ->
    spec_multistep H (tUnion T (tCouple(tid,unlocked(S++[fAct M' E M'' d n]), s2, e1)
                                       (n::tid,locked S',nil,e2)))
                   H' (tUnion T' (tCouple(tid,unlocked(s1'++[fAct M' E M'' d n]),s2,e1')
                                         (n::tid,locked s1'',nil,e2'))) -> 
    exists H'' T'',
      spec_multistep H (tUnion T (tCouple(tid,unlocked(S++[fAct M' E M'' d n]),s2,e1)
                                         (n::tid,locked nil,nil,e2)))
                     H'' (tUnion T'' (tCouple(tid,unlocked(S++[fAct M' E M'' d n]),s2,x)
                                             (n::tid,locked S',nil,x0))) /\
      spec_multistep H'' (tUnion T'' (tCouple(tid,unlocked(S++[fAct M' E M'' d n]),s2,x)
                                             (n::tid,locked S',nil,x0)))
                 H' (tUnion T' (tCouple(tid,unlocked(s1'++[fAct M' E M'' d n]),s2,e1')
                                         (n::tid,locked s1'',nil,e2'))) /\
      spec_multistep H T H'' T''. 
Proof.
  intros. genDeps{x;x0}. dependent induction H4; intros.
  {unfoldTac. repeat rewrite coupleUnion in x. 
   repeat rewrite <- Union_associative in x. apply UnionEqTID in x. invertHyp. inv H3. 
   {apply UnionEqTID in H. invertHyp. inv H. destruct s1'; inv H6. Focus 2. invertListNeq. 
    inv H0; try solve[invertListNeq]. simpl. 


Theorem forkCatchup : forall H T H' T' x x0 tid s1' s1'' s2 e1 e1' e2 e2' M' M'' n E d,
    eraseTrm s1' e1' x -> eraseTrm s1'' e2' x0 -> n = numForks' s2 -> 
    spec_multistep H (tUnion T (tCouple(tid,unlocked[fAct M' E M'' d n], s2, e1)
                                       (n::tid,locked nil,nil,e2)))
                   H' (tUnion T' (tCouple(tid,unlocked(s1'++[fAct M' E M'' d n]),s2,e1')
                                         (n::tid,locked s1'',nil,e2'))) -> 
    exists H'' T'',
      spec_multistep H (tUnion T (tCouple(tid,unlocked[fAct M' E M'' d n],s2,e1)
                                         (n::tid,locked nil,nil,e2)))
                     H'' (tUnion T'' (tCouple(tid,unlocked[fAct M' E M'' d n],s2,x)
                                             (n::tid,locked nil,nil,x0))) /\
      spec_multistep H'' (tUnion T'' (tCouple(tid,unlocked[fAct M' E M'' d n],s2,x)
                                             (n::tid,locked nil,nil,x0)))
                 H' (tUnion T' (tCouple(tid,unlocked(s1'++[fAct M' E M'' d n]),s2,e1')
                                         (n::tid,locked s1'',nil,e2'))) /\
      spec_multistep H T H'' T''. 
Proof.
  intros. genDeps{x;x0}. dependent induction H3; intros.
  {unfoldTac. repeat rewrite coupleUnion in x. 
   repeat rewrite <- Union_associative in x. apply UnionEqTID in x. invertHyp. 
   inv H3. apply UnionEqTID in H. invertHyp. inv H. destruct s1'; inv H5. 
   inv H0; try invertListNeq. inv H1; try invertListNeq. exists h. exists T'. 
   split. constructor. split. constructor. constructor. invertListNeq. }
  {copy x. copy H. apply specStepSingleton in H4. invertHyp. copy x. unfoldSetEq x.
   assert(tIn (tUnion T0 (tSingleton x2)) x2). apply Union_intror. constructor.
   apply H5 in H7. inv H7. 
   {eapply IHspec_multistep in H0; eauto. invertHyp. exists x. exists x3. 
    split. copy H8. apply pullOut in H9. rewrite H9. unfoldTac. rewrite UnionSwap. 
    econstructor. eapply specStepChangeUnused. eauto. unfoldTac. rewrite <- UnionSwap.
    eauto. split. auto. copy H8. apply pullOut in H9. rewrite H9. econstructor. 
    eapply specStepChangeUnused. eauto. auto. apply UnionSingletonCoupleEq in H2. 
    rewrite H2. unfoldTac. rewrite UnionSwap. auto. auto. }
   {inv H8. unfoldTac. rewrite coupleUnion in H2. rewrite <- Union_associative in H2.
    rewrite UnionSwap in H2. apply UnionEqTID in H2. invertHyp. 
    inv H; unfoldTac; invertHyp; invThreadEq. 
    {eapply IHspec_multistep in H0. invertHyp. exists x. exists x2. 
     split. rewrite coupleUnion. rewrite <- Union_associative. rewrite UnionSwap. 
     econstructor. eapply SBasicStep. eauto. constructor. unfoldTac. 
     rewrite <- UnionSwap. rewrite Union_associative. rewrite <- coupleUnion. 
     eauto. split. eassumption. assumption.  auto. rewrite Union_associative. 
     rewrite <- coupleUnion. rewrite couple_swap. auto. auto. auto. }
    {simpl in *. copy H3. eapply consedActEq in H3. Focus 2. apply Union_intror. simpl. 
     rewrite app_nil_l. constructor. Focus 2. apply Union_intror. constructor. 
     invertHyp. copy H0. apply eraseTrmActTerm in H0. inv H0. 

Theorem raw_unspecHeapCommitCreateFull : forall H x ds a b tid M,
         raw_heap_lookup x H = Some(sfull (unlocked nil) ds (aCons a b) tid M) ->
         raw_unspecHeap (raw_replace x (sfull (unlocked nil) ds (unlocked nil) tid M) H) =
         raw_replace x (sfull (unlocked nil) (Empty_set AST.tid) (unlocked nil) tid M) (raw_unspecHeap H). 
Proof.
  induction H; intros. 
  {inv H. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. 
   {inv H0. simpl. destruct b; simpl; rewrite eq; auto. }
   {simpl in *. erewrite IHlist; eauto. destruct i0. destruct (commit a). 
    simpl. rewrite eq. auto. auto. destruct (commit a); destruct (commit a1); simpl. 
    rewrite eq; auto.  rewrite eq. auto. auto. auto. }
  }
Qed. 

Theorem unspecHeapCommitCreateFull : forall H x ds a b tid M,
         heap_lookup x H = Some(sfull (unlocked nil) ds (aCons a b) tid M) ->
         unspecHeap (replace x (sfull (unlocked nil) ds (unlocked nil) tid M) H) =
         replace x (sfull (unlocked nil) (Empty_set AST.tid) (unlocked nil) tid M) (unspecHeap H). 
Proof. intros. destruct H. simpl. apply rawHeapsEq. eapply raw_unspecHeapCommitCreateFull; eauto. 
Qed. 

Theorem raw_extendReplaceSwitch : forall (T:Type)x x' (v v':T) H z,
                                x <> x' -> raw_heap_lookup x' H = Some z -> 
                                raw_extend x v (raw_replace x' v' H) = raw_replace x' v' (raw_extend x v H). 
Proof.
  induction H; intros. 
  {inv H0. }
  {simpl in *. destruct a. destruct (beq_nat x' i) eqn:eq1. 
   {inv H1. rewrite <- beq_nat_false_iff in H0. rewrite beq_nat_sym in H0. rewrite H0.
    auto. }
   {rewrite <- beq_nat_false_iff in H0. rewrite beq_nat_sym in H0. rewrite H0. 
    rewrite H0 in IHlist. unfold raw_extend. auto. }
  }
Qed. 

Theorem extendReplaceSwitch : forall (T:Type)x x' (v v':T) H z p p',
                                x <> x' -> heap_lookup x' H = Some z -> 
                                extend x v (replace x' v' H) p' = replace x' v' (extend x v H p). 
Proof.
  intros. destruct H. apply rawHeapsEq. eapply raw_extendReplaceSwitch; eauto. 
Qed. 

Theorem writeFastForward : forall H T H' T' TID x M' E M'' s2 d s1' M,
         heap_lookup x H = Some(sempty (unlocked nil)) -> decompose M' E (put (fvar x) M'') ->
         spec_multistep H (tUnion T (tSingleton(TID,unlocked nil,s2,M'))) H' 
                        (tUnion T' (tSingleton(TID,unlocked(s1'++[wAct x M' E M'' d]),s2,M))) ->
         exists H'' T'' a b,
           spec_multistep H (tUnion T (tSingleton(TID,unlocked nil,s2,M'))) H''
                         (tUnion T'' (tSingleton(TID,unlocked [wAct x M' E M'' d],s2,fill E (ret unit)))) /\
           spec_multistep H'' (tUnion T'' (tSingleton(TID,unlocked [wAct x M' E M'' d],s2,fill E (ret unit))))
                          H' (tUnion T' (tSingleton(TID,unlocked(s1'++[wAct x M' E M'' d]),s2,M)))  /\
           spec_multistep (replace x (sfull (unlocked []) (Empty_set AST.tid) (unlocked []) TID M'') H) T 
                          (replace x (sfull (unlocked []) (Empty_set AST.tid) (unlocked []) TID M'')H'') T'' /\ 
           heap_lookup x H'' = Some(sfull (unlocked nil) (Empty_set tid) (aCons a b) TID M'').
Proof.
  intros. dependent induction H2. 
  {apply UnionEqTID in x. invertHyp. inv H2. invertListNeq. }
  {copy x. copy H3. apply specStepSingleton in H5. invertHyp. copy x. unfoldSetEq x.
   assert(tIn (tUnion T0 (tSingleton x1)) x1). apply Union_intror. constructor.
   apply H6 in H8. inv H8. 
   {copy H3. eapply specStepEmptyIVar in H3; eauto. Focus 3. apply Union_intror. constructor.
    eapply IHspec_multistep in H1. Focus 2. eassumption. Focus 2. auto. Focus 3. auto. 
    invertHyp. exists x. exists x2. exists x3. exists x4. split. copy H9. apply pullOut in H12. rewrite H12. 
    unfoldTac. rewrite UnionSwap. econstructor. eapply specStepChangeUnused. eauto. 
    unfoldTac. rewrite <- UnionSwap. eassumption. split. eassumption. split.
    apply pullOut in H9. rewrite H9. clear H9. inv H8; unfoldTac; invertHyp.
    {econstructor. eapply SBasicStep; eauto. auto. }
    {econstructor. eapply SFork. auto. eauto. }
    {destruct (beq_nat x5 x0) eqn:eq. apply beq_nat_true in eq. subst. 
     erewrite HeapLookupReplace in H3; eauto. inv H3. econstructor. eapply SGet with(x:=x5). 
     rewrite <- lookupReplaceNeq. eauto. apply beq_nat_false in eq. auto. auto. 
     rewrite lookupReplaceSwitch. unfoldTac. eassumption. apply beq_nat_false in eq. auto. }
    {destruct (beq_nat x5 x0) eqn:eq. apply beq_nat_true in eq. subst.
     erewrite HeapLookupReplace in H3; eauto. inv H3. econstructor. eapply SPut with(x:=x5). 
     rewrite <- lookupReplaceNeq. eauto. apply beq_nat_false in eq. auto. auto. 
     rewrite lookupReplaceSwitch. eassumption. apply beq_nat_false in eq. auto. }
    {destruct (beq_nat x5 x0)eqn:eq. apply beq_nat_true in eq. subst. rewrite lookupExtend in H3. 
     inv H3. destruct b; inv H9. econstructor. eapply SNew with(x:=x5). auto. 
     erewrite extendReplaceSwitch; eauto. apply beq_nat_false in eq. auto. }
    {econstructor. eapply SSpec; eauto. eassumption. }
    auto. apply UnionSingletonEq in H4. rewrite H4. unfoldTac. rewrite UnionSwap. auto. auto. 
    apply UnionSingletonEq in H4. rewrite H4. constructor. apply Union_intror. constructor. auto. 
   }
   {inv H9. apply UnionEqTID in H4. invertHyp. clear H4 H9 H10. 
    exists (replace x0 (sfull (unlocked nil) (Empty_set tid) (aCons (wAct x0 M' E M'' d) (unlocked nil)) TID M'') H). 
    exists T. exists (wAct x0 M' E M'' d). exists (unlocked nil). split. econstructor. 
    eapply SPut. eauto. auto. simpl. constructor. split. inv H3; unfoldTac; invertHyp; invThreadEq. 
    {inv H8; copy d; eapply uniqueCtxtDecomp in H; eauto; invertHyp; inv H8. }
    {copy d. copy d0. eapply uniqueCtxtDecomp in H; eauto. invertHyp. inv H8. }
    {copy d. copy d0. eapply uniqueCtxtDecomp in H3; eauto. invertHyp. solveByInv. }
    {copy d. copy d0. eapply uniqueCtxtDecomp in H3; eauto. invertHyp. inv H10. copy H2. 
     rewrite H0 in H8. inv H8. assert(d=d0). apply proof_irrelevance. subst. eassumption. }
    {copy d; copy d0. eapply uniqueCtxtDecomp in H3; eauto. invertHyp. solveByInv. }
    {copy d; copy d0. eapply uniqueCtxtDecomp in H; eauto. invertHyp. solveByInv. }
    split. rewrite replaceOverwrite. constructor. erewrite HeapLookupReplace; eauto. }
  }
  Grab Existential Variables. rewrite <- lookupReplaceNeq. auto. apply beq_nat_false in eq. auto.  
Qed. 

Theorem specStepFullIVar : forall x sc ds s N H T H' t' tid TID s1 s2 M,
                              heap_lookup x H = Some(sfull sc ds s tid N) -> 
                              spec_step H T (tSingleton (TID,s1,s2,M)) H' T t' ->
                              (heap_lookup x H' = Some(sfull sc ds s tid N) \/
                               heap_lookup x H' = Some(sfull sc (Add AST.tid ds TID) s tid N)).
Proof. 
  intros. inv H1; eauto.
  {unfoldTac; invertHyp. invThreadEq. destruct (beq_nat x x0)eqn:eq. 
   {apply beq_nat_true in eq. subst. rewrite H3 in H0. inv H0. right. 
    erewrite HeapLookupReplace; eauto. }
   {apply beq_nat_false in eq. econstructor. rewrite <- lookupReplaceNeq; eauto. }
  }
  {unfold tSingleton in *; invertHyp. destruct (beq_nat x x0)eqn:eq. 
   {apply beq_nat_true in eq. subst. rewrite H3 in H0. inv H0.  }
   {apply beq_nat_false in eq. econstructor. rewrite <- lookupReplaceNeq; eauto. }
  }
  {unfold tSingleton in *; invertHyp. destruct (beq_nat x x0)eqn:eq. 
   {apply beq_nat_true in eq. subst. copy p. rewrite H0 in H1. inv H1. }
   {apply beq_nat_false in eq. econstructor. erewrite <- lookupExtendNeq; eauto. }
  }
Qed. 

Theorem writeSimPureSteps : forall H T H' T' TID x M' E M'' d N N' N'' s2 s1' ds ds',
       eraseTrm s1' N' N'' -> 
       heap_lookup x H = Some(sfull (unlocked nil) ds (unlocked [wAct x M' E M'' d]) TID M'') ->       
       heap_lookup x H' = Some(sfull (unlocked nil) ds'(unlocked [wAct x M' E M'' d]) TID M'') -> 
       spec_multistep H (tUnion T (tSingleton(TID,unlocked[wAct x M' E M'' d],s2,N))) H'
                      (tUnion T' (tSingleton(TID,unlocked(s1'++[wAct x M' E M'' d]),s2,N'))) ->
       exists H'' T'',
         spec_multistep H (tUnion T (tSingleton(TID,unlocked[wAct x M' E M'' d],s2,N))) 
                        H'' (tUnion T'' (tSingleton(TID,unlocked[wAct x M' E M'' d],s2,N''))) /\
         spec_multistep H'' (tUnion T'' (tSingleton(TID,unlocked[wAct x M' E M'' d],s2,N''))) 
                        H' (tUnion T' (tSingleton(TID,unlocked(s1'++[wAct x M' E M'' d]),s2,N'))) /\
         spec_multistep (replace x (sfull (unlocked []) ds (unlocked []) TID M'') H) T 
                        (replace x (sfull (unlocked []) ds' (unlocked []) TID M'')H'') T''.
Proof.
  intros. genDeps{N'';ds; ds'}. dependent induction H3; intros.
  {apply UnionEqTID in x. invertHyp. inv H. destruct s1'; inv H5. inv H0; try invertListNeq. 
   rewrite H2 in H1. inv H1. repeat econstructor. invertListNeq. }
  {copy x. copy H0. apply specStepSingleton in H6. invertHyp. unfoldSetEq H5. 
   assert(tIn (tUnion T0(tSingleton x1)) x1). apply Union_intror. constructor. apply H6 in H5. 
   inv H5. 
   {copy H0. destruct x1. destruct p. destruct p. eapply specStepFullIVar in H5; eauto. inv H5. 
    {eapply IHspec_multistep in H9; eauto. invertHyp. exists x1. exists x2. split. 
     apply pullOut in H8. rewrite H8. unfoldTac. rewrite UnionSwap. econstructor.
     eapply specStepChangeUnused. eassumption. unfoldTac. rewrite <- UnionSwap. eassumption. 
     split. eassumption. apply pullOut in H8. rewrite H8. clear H8. 
     inv H0; unfoldTac; invertHyp; invThreadEq. 
     {econstructor. eapply SBasicStep; eauto. eassumption. }
     {econstructor. eapply SFork; eauto. eassumption. }
     {destruct (beq_nat x3 x0) eqn:eq. apply beq_nat_true in eq. subst. rewrite H1 in H10. 
      inv H10. econstructor. eapply SGet with (x:=x0). erewrite HeapLookupReplace; eauto. 
      auto. eassumption. 



Theorem raw_lookupUnspecEmpty : forall x H ds a b t N,
                              raw_heap_lookup x H = Some(sfull (unlocked nil) ds (aCons a b) t N) ->
                              raw_heap_lookup x (raw_unspecHeap H) = Some(sempty (unlocked nil)). 
Proof.
  induction H; intros. 
  {inv H. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. 
   {inv H0. simpl. destruct b; simpl; rewrite eq; auto. }
   {destruct i0. destruct (commit a). simpl. rewrite eq. eapply IHlist; eauto. 
    eapply IHlist; eauto. destruct (commit a); destruct (commit a1). 
    simpl. rewrite eq. eapply IHlist; eauto. simpl. rewrite eq. eauto. eauto. eauto. }
  }
Qed. 
Theorem lookupUnspecEmpty : forall x H ds a b t N,
                              heap_lookup x H = Some(sfull (unlocked nil) ds (aCons a b) t N) ->
                              heap_lookup x (unspecHeap H) = Some(sempty (unlocked nil)). 
Proof.
  intros. destruct H; simpl. eapply raw_lookupUnspecEmpty; eauto. 
Qed. 

Ltac copyAs H n := 
  match type of H with
      |?x => assert(n:x) by auto
  end.
Ltac falseDecomp :=
  match goal with
      |H:decompose ?M ?E ?e,H':decompose ?M ?E' ?e' |- _ => 
       let n := fresh
       in let n' := fresh
          in copyAs H n; copyAs H' n'; eapply uniqueCtxtDecomp in n; eauto; inversion n as [F1 F2];
             inv F2
  end. 

Theorem specMultiStepFullIVar : forall x sc ds s N H T T' H' tid,
                              heap_lookup x H = Some(sfull sc ds s tid N) -> 
                              spec_multistep H T H' T' ->
                              exists ds', heap_lookup x H' = Some(sfull sc ds' s tid N).
Proof. 
  intros. genDeps{ds; sc; s; tid; N}. induction H1; intros. 
  {eauto. }
  {copy H. apply specStepSingleton in H2. invertHyp. eapply specStepFullIVar in H; eauto. 
   invertHyp. eauto. }
Qed. 

Theorem ivarSpecStack : forall H T H' T' ds tid a b x M' E M'' d s2 s1' M,
         spec_multistep H (tUnion T(tSingleton (tid, unlocked [], s2, M'))) H'
                        (tUnion T' (tSingleton (tid, unlocked (s1'++[wAct x M' E M'' d]),s2,M))) ->
         heap_lookup x H = Some(sempty (unlocked nil)) ->
         heap_lookup x H' = Some(sfull (unlocked nil) ds (aCons a b) tid M'') -> aCons a b = unlocked[wAct x M' E M'' d]. 
Proof.
  intros. genDeps{a; b; ds}. dependent induction H0; intros. 
  {apply UnionEqTID in x. invertHyp. inv H. invertListNeq. }
  {copy x. copy H. apply specStepSingleton in H4. invertHyp. unfoldSetEq H3. 
   assert(tIn (tUnion T0(tSingleton x1)) x1). apply Union_intror. constructor. apply H4 in H3. 
   inv H3. 
   {copy H. eapply specStepEmptyIVar in H; eauto. Focus 3. apply Union_intror. constructor. 
    Focus 2. apply UnionSingletonEq in x;auto. rewrite x. constructor. apply Union_intror. 
    constructor. eapply IHspec_multistep; eauto. apply UnionSingletonEq in x; auto. rewrite x. 
    unfoldTac. rewrite UnionSwap. auto. }
   {inv H6. inversion H; subst; unfoldTac; invertHyp; invThreadEq; try solve[falseDecomp]. 
    {inv H6; falseDecomp. }
    {falseDecomp. invertHyp. inv H9. simpl in *. eapply specMultiStepFullIVar with(x:=x0) in H0; eauto. 
     Focus 2. erewrite HeapLookupReplace; eauto. invertHyp. rewrite H2 in H3. inv H3. 
     assert(d=d0). apply proof_irrelevance. subst. auto. }
   }
  }
Qed. 





Theorem stepWF : forall H T t H' t', 
                   wellFormed H (tUnion T t) -> step H T t (OK H' T t') ->
                   wellFormed H' (tUnion T t'). 
Proof.
  intros. inversion H1; subst.      
  {destruct s1.  
   {inv H0. inv H2. econstructor; eauto. rewrite unspecUnionComm in *. 
    rUnspecAll. unfoldTac. rewrite union_empty_r in *. eapply spec_multi_trans; eauto. 
    econstructor. eapply SBasicStep. eauto. constructor. constructor. } 
   {destruct l. 
    {inv H0. inv H2. econstructor; eauto. rewrite unspecUnionComm in *. rUnspecAll. 
     apply spec_multi_unused in H3. rewrite spec_multi_unused. auto. }
    {inversion H0; subst. inversion H2; subst. econstructor; eauto. 
    rewrite unspecUnionComm in *. eUnspec. erewrite unspecSingleton; eauto. 
    erewrite unspecSingleton in H3; eauto. eapply spec_multi_trans. eassumption. econstructor. 
    eauto. rewriteEmpty HNil. eapply SBasicStep; eauto. constructor. constructor. 
    uCons a l. eapply unspecTwoActs. eauto. }
   }
   {inv H0. inv H2. econstructor; eauto. rewrite unspecUnionComm in *. rUnspecAll. 
    eapply spec_multi_trans. eassumption. econstructor. eapply SBasicStep; eauto.
    constructor. constructor. }
  }
  {inv H0. inv H2. econstructor; eauto. destruct s1.
   {simpl. unfoldTac. rewrite coupleUnion in *. repeat rewrite unspecUnionComm in *. 
    repeat rUnspecAll. unfoldTac. repeat rewrite union_empty_r in *. eapply spec_multi_trans.
    eassumption. econstructor. eapply SFork. auto. rewrite <- coupleUnion. simpl. constructor. }
   {destruct l. 
    {unfoldTac. rewrite coupleUnion. repeat rewrite unspecUnionComm in *. 
     erewrite unspecSingleton;try unspecThreadTac; auto. erewrite unspecSingleton; eauto. 
     unfold tUnion. rewrite union_empty_r. eapply spec_multi_trans. copy d. apply decomposeEq in H. subst. 
     erewrite unspecSingleton in H3; eauto. copy d. apply decomposeEq in H. rewrite <- H.  
     econstructor. auto. unfold tUnion. eapply SFork; eauto. rewrite <- coupleUnion. unfoldTac. 
     constructor. simpl. copy d. apply decomposeEq in H; subst. eapply unspecFork.
     rewrite app_nil_l. auto. }
   {unfoldTac. rewrite coupleUnion. repeat rewrite unspecUnionComm in *. 
    assert(exists t', unspecThread (tid, unlocked(a :: l), s2, t0) t'). 
    apply unspecThreadTotal. invertHyp. erewrite unspecSingleton; eauto. 
    erewrite unspecSingleton; eauto. unfold tUnion. rewrite union_empty_r. 
    erewrite unspecSingleton in H3; eauto. eapply spec_multi_trans. eassumption. 
    econstructor. eapply SFork. auto. rewrite <- coupleUnion. constructor. uCons a l.
    rewrite unspecTwoActs'. eauto. }
   }
   {simpl. unfoldTac. rewrite coupleUnion in *. repeat rewrite unspecUnionComm in *. 
    repeat rUnspecAll. unfoldTac. repeat rewrite union_empty_r in *. eapply spec_multi_trans.
    eassumption. econstructor. eapply SFork. auto. rewrite <- coupleUnion. constructor. }
  }
  {inv H0. inv H3. econstructor; eauto. erewrite unspecHeapRBRead; eauto. destruct s1.  
   {rewrite unspecUnionComm in *. simpl. rUnspecAll. unfoldTac. rewrite union_empty_r in *. 
    eapply spec_multi_trans. eassumption. econstructor. eapply SGet; eauto. constructor. }
   {destruct l.
    {unfoldTac. rewrite unspecUnionComm in *. simpl. rUnspecAll. eapply spec_multi_trans. 
     eassumption. econstructor. eapply SGet; eauto. constructor. eapply unspecRead. 
     rewrite app_nil_l. auto. }
   {rewrite unspecUnionComm in *. eUnspec. erewrite unspecSingleton; eauto. 
    erewrite unspecSingleton in H4. Focus 2. uCons a l. rewrite <- unspecTwoActs'. eauto. 
    eapply spec_multi_trans. eassumption. econstructor. eapply SGet; eauto. constructor. }
   }
   {rewrite unspecUnionComm in *. simpl. rUnspecAll. 
    eapply spec_multi_trans. eassumption. econstructor. eapply SGet; eauto. constructor. }
  }
  {inv H0. inv H3. econstructor; eauto. erewrite unspecHeapAddWrite; eauto. destruct s1.  
   {rewrite unspecUnionComm in *. simpl. rUnspecAll. unfoldTac. rewrite union_empty_r in *. 
    eapply spec_multi_trans. eassumption. econstructor. eapply SPut; eauto. constructor. }
   {destruct l. 
    {unfold tUnion in *. rewrite unspecUnionComm in *. simpl. rUnspecAll. Focus 2. 
     unspecThreadTac. rewrite app_nil_l; auto. eapply spec_multi_trans. eassumption. 
     econstructor. eapply SPut; eauto. constructor. }
    {rewrite unspecUnionComm in *. eUnspec. rUnspecAll. eapply spec_multi_trans. 
     eassumption. econstructor. eapply SPut; eauto. constructor. uCons a l.
     rewrite <- unspecTwoActs'. eauto. uCons a l. rewrite <- unspecTwoActs'; eauto. }
   }
   {rewrite unspecUnionComm in *. simpl. rUnspecAll. eapply spec_multi_trans. 
    eassumption. econstructor. eapply SPut; eauto. constructor. }
  }   
  {copy H5. unfoldTac. rewrite <- Union_associative in H0. rewrite wfFrame in H0. 
   eapply rollbackWF in H5; eauto. Focus 2. unfold commitPool. intros. inv H3; auto.
   econstructor; eauto. uCons (wAct x t0 E N d) (@nil action). rewrite unspecHeapAddWrite; auto. 
   inv H5. inv H6. rewrite unspecUnionComm in H7. repeat rewrite unspecUnionComm. simpl. 
   erewrite unspecSingleton. Focus 2. unspecThreadTac. rewrite app_nil_l. auto. 
   unfoldTac. rewrite <- Union_associative. erewrite <- spec_multi_unused in H7. 
   eapply spec_multi_trans. eassumption. econstructor. eapply SPut; eauto. 
   simpl. rewrite <- Union_associative. constructor. }
  {inv H0. inv H3. econstructor; eauto. erewrite unspecHeapExtend; eauto. destruct s1. 
   {rewrite unspecUnionComm in *. simpl. rUnspecAll. unfoldTac. rewrite union_empty_r in *. 
    eapply spec_multi_trans. eassumption. copy d. apply decomposeEq in H0; subst. 
    econstructor. eapply SNew; eauto. constructor. }
   {destruct l. 
    {unfold tUnion in *. rewrite unspecUnionComm in *. simpl. rUnspecAll. Focus 2. 
     unspecThreadTac. rewrite app_nil_l; auto. copy d. apply decomposeEq in H0; subst. 
     eapply spec_multi_trans. eassumption. econstructor. eapply SNew; eauto. constructor. }
    {copy d. apply decomposeEq in H0; subst. rewrite unspecUnionComm in *. eUnspec. 
     rUnspecAll. eapply spec_multi_trans. eassumption. econstructor. eapply SNew; eauto. 
     constructor. uCons a l. rewrite <- unspecTwoActs'. eauto. uCons a l. 
     rewrite <- unspecTwoActs'; eauto. }
   }
   {rewrite unspecUnionComm in *. simpl. rUnspecAll. 
    eapply spec_multi_trans. eassumption. copy d. apply decomposeEq in H0; subst. 
    econstructor. eapply SNew; eauto. constructor. }
  }   
  {inv H0. inv H2. econstructor; eauto. destruct s1.  
   {unfoldTac. rewrite coupleUnion in *. repeat rewrite unspecUnionComm in *. simpl. 
    repeat rUnspecAll. unfoldTac. repeat rewrite union_empty_r in *. eapply spec_multi_trans. 
    eassumption. econstructor. eapply SSpec; eauto. rewrite <- coupleUnion. constructor. }
   {destruct l.
    {unfold tCouple. rewrite coupleUnion. repeat rewrite unspecUnionComm in *. 
     erewrite unspecSingleton. Focus 2. eapply unspecSpecret. rewrite app_nil_l. simpl. auto. 
     copy d. apply decomposeEq in H. subst. auto. erewrite unspecSingleton; eauto. unfoldTac. 
     rewrite union_empty_r.  erewrite unspecSingleton in H3; eauto. eapply spec_multi_trans. 
     eassumption. econstructor. eapply SSpec; eauto. unfold tUnion. rewrite <- coupleUnion. 
     constructor. }
    {unfoldTac. rewrite coupleUnion. repeat rewrite unspecUnionComm in *. foldTac. eUnspec. 
     erewrite unspecSingleton in H3; eauto. repeat erewrite unspecSingleton; eauto. unfoldTac. 
     rewrite union_empty_r. eapply spec_multi_trans. eassumption. econstructor. eapply SSpec. 
     rewrite <- coupleUnion. constructor. uCons a l. rewrite unspecTwoActs'. eauto. }
   }
   {unfoldTac. rewrite coupleUnion in *. repeat rewrite unspecUnionComm in *. simpl. 
    repeat rUnspecAll. unfoldTac. repeat rewrite union_empty_r in *. eapply spec_multi_trans. 
    eassumption. econstructor. eapply SSpec; eauto. rewrite <- coupleUnion. constructor. }
  }  
  {inv H0. inv H2. econstructor; eauto. unfoldTac. rewrite couple_swap in H3. 
   rewrite coupleUnion in H3. repeat rewrite unspecUnionComm in *. 
   erewrite unspecSingleton in H3; eauto. erewrite unspecSingleton in H3; eauto. 
   unfoldTac. repeat rewrite <- Union_associative in H3. rewrite spec_multi_unused in H3. 
   destructLast s1. 
   {simpl. erewrite unspecSingleton; eauto. rewrite spec_multi_unused. unfoldTac. 
    eapply simSpecJoin in H3. eauto. }
   {invertHyp. eraseTrmTac (x0++[x]) M. copy H0. 
    eapply wrapEraseTrm with(N:=N1)(E:=E)(N':=(specRun(ret N1) N0))in H0.
    erewrite unspecSingleton. Focus 2. apply unspecEraseTrm; eauto.
    eapply specFastForward in H3; eauto. invertHyp. eapply spec_multi_trans. 
    eapply simTSteps in H2. eassumption. eapply simSpecJoin' in H4. simpl in *.
    eauto. eauto. constructor. introsInv. }
  }
  {copy H13. unfoldTac. rewrite <- Union_associative. rewrite wfFrame. Focus 2. 
   unfold commitPool. intros. inv H3. auto. rewrite <- Union_associative in H0. 
   rewrite wfFrame in H0. Focus 2. unfold commitPool; intros. inv H3. auto.
   eapply rollbackWF; eauto. }
  {inv H0. inv H2. econstructor; eauto. rewrite unspecUnionComm in *. rUnspecAll. 
   rewrite spec_multi_unused in H3. rewrite spec_multi_unused. auto. }
  {inv H0. inv H3. econstructor; eauto. erewrite unspecHeapRBRead; eauto. 
   rewrite unspecUnionComm in *. erewrite unspecSingleton in H4. Focus 2. unspecThreadTac. 
   auto. eraseTrmTac s1' M. erewrite unspecSingleton. Focus 2. apply unspecEraseTrm; eauto. 
   
   admit. }
  {inv H0. inv H3. econstructor; eauto. erewrite unspecHeapCommitCreateFull; eauto.
   rewrite unspecUnionComm in *. erewrite unspecSingleton in H4. Focus 2. unspecThreadTac. 
   auto. eraseTrmTac s1' M. erewrite unspecSingleton. Focus 2. apply unspecEraseTrm; eauto.  
   copy H4. eapply ivarSpecStack in H0; eauto. Focus 2. eapply lookupUnspecEmpty; eauto.
   rewrite H0 in H8. eapply writeFastForward in H4; eauto. Focus 2. eapply lookupUnspecEmpty; eauto. 
   rewrite <- H0 in H8. eauto. invertHyp. eapply spec_multi_trans. rewrite spec_multi_unused. 
   eassumption. eapply writeSimPureSteps in H3; eauto. invertHyp. eapply spec_multi_trans. 
   rewrite spec_multi_unused. eassumption. Focus 2. 

         
                      



inv H3. econstructor; eauto. unfoldTac. admit. }
  {admit. }
  {admit. }
  {inv H0. inv H2. econstructor; eauto. unfoldTac. rewrite coupleUnion in *. 
   repeat rewrite unspecUnionComm in *. eraseTrmTac s1' M. rUnspecAll. 
   Focus 2. unspecThreadTac; eauto. Focus 3. unspecThreadTac; eauto. 
   Focus 2. apply unspecEraseTrm; eauto. eraseTrmTac s1'' N. rUnspecAll. Focus 2. 
   apply unspecEraseTrm. eauto. unfoldTac. rewrite union_empty_r in H3. 
   rewrite <- coupleUnion in H3. eapply forkFastForward in H3; eauto. invertHyp.
   eapply spec_multi_trans. erewrite spec_multi_unused. eassumption. 
   repeat rewrite <- coupleUnion. eapply forkCatchup in H3; eauto. 
   invertHyp. eapply spec_multi_trans. rewrite spec_multi_unused. eassumption. 
   
   




  




aldsfhlasdkjhfasd