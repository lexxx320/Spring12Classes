Require Import erasure. 
Require Import specIndependence.   
Require Import writeIndependence. 
Require Import IndependenceCommon. 
Require Import ReadIndependence. 
Require Import newIndependence.  
Require Import ForkIndependence.
Require Import PopSpecInd. 
Require Import rollbackWellFormed. 

Ltac rewriteEmpty xs := 
      match xs with
          |HNil => unfold tUnion; try rewrite union_empty_l; try rewrite union_empty_r
          |HCons ?x ?xs' => unfold tUnion in x; try rewrite union_empty_l in x; 
                          try rewrite union_empty_r in x; rewriteEmpty xs'
      end. 

Ltac foldTac := fold Add in *; fold tAdd in *; fold tUnion in *; fold tSingleton in *; fold tCouple in *.

Ltac invertDecomp :=
  match goal with
    |H:(?a,?b,?c,?d)=(?e,?f,?g,?h) |- _ => inv H
    |H:?x = ?y |- _ => solve[inv H]
    |H:decompose ?M ?E ?e,H':decompose ?M' ?E' ?e' |- _=>
     eapply uniqueCtxtDecomp in H; eauto; invertHyp
  end. 

Theorem appCons : forall (T:Type) x (y:T) z,
                    x ++ [y;z] = (x ++ [y]) ++ [z]. 
Proof. 
  intros. rewrite <- app_assoc. simpl. auto. Qed. 


Ltac monoActs H := 
  eapply monotonicActions in H;[idtac|solveSet|solveSet]. 


Theorem listTailEq : forall (T:Type) a (b:T) c d e,
                       ~List.In b c -> ~List.In b e -> a ++ [b] ++ c = d ++ b::e -> c = e. 
Proof.
  induction a; intros. 
  {simpl in *. destruct d. simpl in *. inv H1. auto. inv H1. exfalso. apply  H. 
   apply in_or_app. right. simpl. left. auto. }
  {destruct d. inv H1. exfalso. apply H0. apply in_or_app. right. 
   simpl. auto. inv H1. eapply IHa; eauto. }
Qed.   

Theorem raw_unpsecHeapCommitNewEmpty : forall x S H,
                                   unique ivar_state S H -> 
                                   raw_heap_lookup x H = Some(sempty SPEC) ->
                                   raw_unspecHeap (raw_replace x (sempty COMMIT) H) =
                                   raw_extend x (sempty COMMIT) (raw_unspecHeap H).
Proof.
  intros. apply heapExtensionality. genDeps{S; x; H}. induction H; intros. 
  {inv H1. }
  {simpl in H1. simpl. destruct a. destruct (beq_nat x i)eqn:eq. 
   {inv H1. destruct (beq_nat x0 x) eqn:eq2. simpl. rewrite eq2. auto. simpl. rewrite eq2. 
    auto. }
   {simpl. destruct i0. 
    {destruct s. 
     {destruct (beq_nat x0 x) eqn:eq2. 
      {simpl in *. inv H0. eapply IHlist with(x0:=x0) in H1; eauto. rewrite eq2 in H1. 
       auto. }
      {erewrite IHlist. simpl. rewrite eq2. auto. eauto. inv H0; eauto. }
     }
     {simpl. destruct(beq_nat x0 i)eqn:eq2. 
      {apply beq_nat_true in eq2. subst. rewrite beq_nat_sym in eq. rewrite eq. auto. }
      {destruct(beq_nat x0 x) eqn:eq3.
       {eapply IHlist with(x0:=x0) in H1. simpl in *. rewrite eq3 in H1. auto. inv H0; eauto. }
       {erewrite IHlist; eauto. simpl. rewrite eq3. auto. inv H0; eauto. }
      }
     }
    }
    {destruct s. 
     {destruct (beq_nat x0 x)eqn:eq2. 
      {eapply IHlist with(x0:=x0) in H1. simpl in *. rewrite eq2 in H1. auto. inv H0; eauto. }
      {erewrite IHlist; eauto. simpl. rewrite eq2. auto. inv H0; eauto. }
     }
     {destruct s0. 
      {destruct (beq_nat x0 x) eqn:eq2. 
       {simpl. apply beq_nat_true in eq2. subst. rewrite eq.
        eapply IHlist with(x0:=x) in H1; eauto. simpl in *. rewrite <- beq_nat_refl in H1. auto. 
        inv H0; eauto. }
       {simpl. destruct (beq_nat x0 i); auto. erewrite IHlist; eauto. simpl. rewrite eq2. auto. 
        inv H0; eauto. }
      }
      {simpl. destruct (beq_nat x0 i) eqn:eq2. 
       {apply beq_nat_true in eq2. subst. rewrite beq_nat_sym in eq. rewrite eq. auto. }
       {destruct (beq_nat x0 x) eqn:eq3. 
        {simpl in *. eapply IHlist with(x0:=x0) in H1. rewrite eq3 in H1. eauto. inv H0; eauto. }
        {erewrite IHlist; eauto. simpl. rewrite eq3. auto. inv H0; eauto. }
       }
      }
     }
    }
   }
  }
Qed. 

Theorem unspecHeapCommitNewEmpty : forall x H p,
                                   heap_lookup x H = Some(sempty SPEC) ->
                                   unspecHeap (replace x (sempty COMMIT) H) =
                                   Heap.extend x (sempty COMMIT) (unspecHeap H) p.
Proof.
  intros. destruct H. simpl in *. apply rawHeapsEq. 
  eapply raw_unpsecHeapCommitNewEmpty; eauto. 
Qed.

Theorem uniqueLookupNone : forall (T:Type) x H S, 
                            unique T S H -> Ensembles.In (AST.id) S x ->
                            raw_heap_lookup x H = None. 
Proof.
  induction H; intros. 
  {auto. }
  {inv H0. simpl. assert(x <> m). intros c. subst. contradiction.
   apply beq_nat_false_iff in H0. rewrite H0. eapply IHlist; eauto.
   constructor. auto. }
Qed. 

Theorem raw_lookupCreatedSpecFull : forall x H ds t0 N s S,
                                  unique ivar_state S H -> 
                                  raw_heap_lookup x H = Some(sfull SPEC ds s t0 N) ->
                                  raw_heap_lookup x (raw_unspecHeap H) = None. 
Proof. 
  induction H; intros. 
  {inv H0; inv H1. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. 
   {inv H0. inv H1. apply unspecUnique in H7; eapply uniqueLookupNone; eauto;
    apply beq_nat_true in eq; subst; apply Ensembles.Union_intror; constructor. }
   {inv H0. destruct i0. destruct s0. eauto. simpl. rewrite eq. eauto. 
    destruct s0; eauto. destruct s1; simpl; rewrite eq; eauto. }
  }
Qed. 

Theorem lookupCreatedSpecFull : forall x H ds t0 N s,
                                  heap_lookup x H = Some(sfull SPEC ds s t0 N) ->
                                  heap_lookup x (unspecHeap H) = None. 
Proof.
  intros. destruct H. simpl. eapply raw_lookupCreatedSpecFull; eauto. 
Qed. 

Theorem raw_lookupCreatedSpecEmpty : forall x H S,
                                  unique ivar_state S H -> 
                                  raw_heap_lookup x H = Some(sempty SPEC) -> 
                                  raw_heap_lookup x (raw_unspecHeap H) = None. 
Proof. 
  induction H; intros. 
  {inv H0; inv H1. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. 
   {inv H0. inv H1; apply unspecUnique in H7; eapply uniqueLookupNone; eauto;
    apply beq_nat_true in eq; subst; apply Ensembles.Union_intror; constructor. }
   {inv H0. destruct i0. destruct s. eauto. simpl. rewrite eq. eauto. 
    destruct s; eauto. destruct s0; simpl; rewrite eq; eauto. }
  }
Qed. 

Theorem lookupCreatedSpecEmpty : forall x H,
                                  heap_lookup x H = Some(sempty SPEC) ->
                                  heap_lookup x (unspecHeap H) = None. 
Proof.
  intros. destruct H. simpl. eapply raw_lookupCreatedSpecEmpty; eauto. 
Qed. 


Theorem PopSpecFastForward : forall H T H' T' tid s1' s1'' N M M' M'' N'' E s2 d,
  decompose M' E (spec M'' N'') -> 
  spec_multistep H (tUnion T (tSingleton(tid,unlocked nil, s2, M')))
                 H' (tUnion T' (tCouple(tid,unlocked(s1'++[srAct M' E M'' N'' d]),s2,M)
                                       (2::tid,locked s1'',nil,N))) ->
  exists H'' T'',
    spec_multistep H (tUnion T (tSingleton(tid,unlocked nil,s2,M')))
                   H'' (tUnion T'' (tCouple(tid,unlocked[srAct M' E M'' N'' d],s2,fill E (specRun M'' N''))
                                          (2::tid,locked nil,nil,N''))) /\
    spec_multistep H'' (tUnion T'' (tCouple(tid,unlocked[srAct M' E M'' N'' d],s2,fill E (specRun M'' N'')) 
                                           (2::tid,locked nil,nil,N'')))
                   H'(tUnion T' (tCouple(tid,unlocked(s1'++[srAct M' E M'' N'' d]),s2,M)
                                       (2::tid,locked s1'',nil,N))) /\
    spec_multistep H T H'' T''. 
Proof.
  intros. dependent induction H1. 
  {unfoldTac. rewrite coupleUnion in x. rewrite Union_associative in x. 
   rewrite UnionSwap in x. apply UnionEqTID in x. invertHyp. inv H. invertListNeq. }
  {startIndCase. destructThread x0. exMid tid H7. 
   {apply UnionEqTID in x. invertHyp. econstructor. econstructor. split. 
    econstructor. eapply SSpec; eauto. simpl. constructor. split; try constructor. 
    inv H; try solve[falseDecomp]. 
    {inv H13; falseDecomp. }
    {simpl in *. copy d0. eapply uniqueCtxtDecomp in H0; eauto. invertHyp. 
     inv H4. proofsEq d d0. eassumption. }
   }
   {apply UnionNeqTID in x. invertHyp. eapply IHspec_multistep in H0; eauto. 
    invertHyp. econstructor. econstructor. split. takeTStep. eassumption. 
    split; eauto. takeTStep. econstructor. eapply specStepChangeUnused; eauto. 
    eauto. rewrite H2. rewrite UnionSubtract. unfoldTac. rewrite UnionSwap; eauto.
    auto. }
  }
Qed. 


Theorem unspecSpecSame : forall tid hd tl s2 M M',
                           unspecPool(tSingleton(tid,unlocked(hd::tl),s2,M)) = 
                           unspecPool(tSingleton(tid,unlocked(hd::tl),s2,M')). 
Proof.
  induction tl; intros; auto. 
Qed. 

Theorem unspecSpecSame' : forall tid hd a tl s2 M M',
            unspecPool(tSingleton(tid,aCons a (unlocked(hd::tl)),s2,M)) = 
            unspecPool(tSingleton(tid,unlocked(hd::tl),s2,M')). 
Proof.
  induction tl; intros; auto. 
  {simpl. destruct tl. auto. erewrite getLastNonEmpty. eauto. }
Qed. 

Theorem unspecEmpty : forall tid s1 s2 M, 
                unspecPool(tSingleton(tid,locked s1,s2,M)) = (Empty_set thread).
Proof.
  intros. simpl. auto. 
Qed. 


Theorem wfWithoutPure' : forall T tid H s2 M, 
                      wellFormed H (tUnion T (tSingleton(tid,unlocked nil, s2,M))) ->
                      wellFormed H T. 
Proof.
  intros. inv H0. constructor; eauto. rewrite unspecUnionComm in H2. simpl in *. 
  eapply smultiWithoutPure; eauto. 
Qed. 

Theorem wfWithoutPure : forall T tid H s2 N M, 
            wellFormed H (tUnion T (tSingleton(tid,specStack nil N, s2,M))) ->
            wellFormed H T. 
Proof.
  intros. inv H0. constructor; eauto. rewrite unspecUnionComm in H2. simpl in *. 
  eapply smultiWithoutPure; eauto. 
Qed. 

Theorem raw_unspecHeapOverwrite : forall x H TID N, 
                    raw_heap_lookup x H = Some(sempty COMMIT) -> 
                    raw_unspecHeap(raw_replace x (sfull COMMIT nil COMMIT TID N) H) = 
                    raw_replace x (sfull COMMIT nil COMMIT TID N) (raw_unspecHeap H).
Proof.
  induction H; intros. 
  {inv H. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. 
   {inv H0. simpl. rewrite eq. auto. }
   {simpl. erewrite IHlist; eauto. destruct i0. destruct s; auto. 
    simpl. rewrite eq. auto. destruct s; auto. destruct s0; 
    simpl; rewrite eq; auto. }
  }
Qed. 
Theorem unspecHeapOverwrite : forall x H TID N, 
                    heap_lookup x H = Some(sempty COMMIT) -> 
                    unspecHeap(replace x (sfull COMMIT nil COMMIT TID N) H) = 
                    replace x (sfull COMMIT nil COMMIT TID N) (unspecHeap H).
Proof.
  intros. destruct H. simpl. apply rawHeapsEq. eapply raw_unspecHeapOverwrite; eauto. 
Qed. 

Theorem stepWithFullIVar : forall H T H' T' x TID N,
                  heap_lookup x H' = Some(sempty COMMIT) -> 
                  heap_lookup x H = Some(sempty COMMIT) -> 
                  spec_multistep H T H' T' ->
                  spec_multistep (replace x (sfull COMMIT nil COMMIT TID N)H) T
                                 (replace x (sfull COMMIT nil COMMIT TID N)H') T'.
Proof.
  intros. induction H2. 
  {constructor. }
  {inv H. 
   {econstructor. eapply SBasicStep; eauto. eauto. }
   {econstructor. eapply SFork; eauto. eauto. }
   {varsEq x0 x. heapsDisagree. econstructor. eapply SGet; eauto.
    erewrite lookupReplaceNeq; eauto. rewrite lookupReplaceSwitch; eauto. 
    eapply IHspec_multistep; eauto. rewrite lookupReplaceNeq; eauto. }
   {varsEq x0 x.
    {eapply smultiFullIVar in H2. Focus 2. erewrite HeapLookupReplace; eauto. 
     invertHyp. heapsDisagree. }
    {econstructor. eapply SPut. erewrite lookupReplaceNeq; eauto. auto. 
     rewrite lookupReplaceSwitch; auto. eapply IHspec_multistep; eauto.
     rewrite lookupReplaceNeq; eauto. }
   }
   {varsEq x0 x. heapsDisagree. econstructor. eapply SNew with (x:=x0); eauto.
    erewrite extendReplaceSwitch; eauto. eapply IHspec_multistep; eauto. 
    rewrite lookupExtendNeq; eauto. }
   {econstructor. eapply SSpec; eauto. eauto. }
  }
  Grab Existential Variables. rewrite lookupReplaceNeq; eauto. 
Qed. 


Theorem raw_lookupUnspecCommitEmpty : forall H x,
                  raw_heap_lookup x H = Some(sempty COMMIT) ->
                  raw_heap_lookup x (raw_unspecHeap H) = Some (sempty COMMIT). 
Proof.
  induction H; intros. 
  {inv H. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. 
   {inv H0. simpl. rewrite eq. auto. }
   {destruct i0; eauto. destruct s; eauto. simpl. rewrite eq. 
    auto. destruct s; eauto. destruct s0; simpl; rewrite eq; eauto. }
  }
Qed. 

Theorem lookupUnspecCommitEmpty : forall x H,
                  heap_lookup x H = Some(sempty COMMIT) ->
                  heap_lookup x (unspecHeap H) = Some (sempty COMMIT). 
Proof.
  intros. destruct H. simpl. eapply raw_lookupUnspecCommitEmpty; eauto. 
Qed. 

Theorem prog_stepWF : forall H T t H' t', 
                   wellFormed H (tUnion T t) -> prog_step H T t (OK H' T t') ->
                   wellFormed H' (tUnion T t'). 
Proof.
  intros. inversion H1; subst.      
  {inv H0. constructor. rewrite unspecUnionComm in *. simpl in *.
   rewrite spec_multi_unused in *. auto. }
  {unfoldTac. rewrite AddUnion in H0. rewrite Union_associative in H0. 
   apply wfWithoutPure' in H0. copy H7. eapply rollbackWF in H7; eauto. 
   inv H7. constructor. unfoldTac. rewrite AddUnion in *. rewrite Union_associative. 
   rewrite unspecUnionComm in *. simpl in *. rewrite spec_multi_unused. copy H2.
   erewrite unspecHeapOverwrite; auto. apply stepWithFullIVar; auto. 
   eapply lookupUnspecCommitEmpty; eauto. rewrite unspecUnionComm in *. eauto. }
  {inv H0. econstructor; eauto. unfoldTac. rewrite couple_swap in H2. 
   rewrite coupleUnion in H2. repeat rewrite unspecUnionComm in *. unfoldTac.
   repeat rewrite Union_associative in H2. simpl in H2.
   rewrite spec_multi_unused in H2. destructLast s1. 
   {simpl. rewrite spec_multi_unused. eapply simSpecJoin in H2. eauto. }
   {invertHyp. eraseTrmTac (x0++[x]) M. copy H0. 
    eapply wrapEraseTrm with(N:=N1)(E:=E)(N':=(specRun(ret N1) N0))in H0.
    erewrite unspecEraseTrm; eauto. eapply specFastForward in H2; eauto. 
    invertHyp. eapply spec_multi_trans. eapply simTSteps in H3. eapply H3. 
    eapply simSpecJoin' in H4. simpl in *.
    eauto. eauto. constructor. introsInv. }
  }
  {unfoldTac. rewrite coupleUnion in H0. repeat rewrite Union_associative in H0. 
   apply wfWithoutPure' in H0. copy H9. eapply rollbackWF in H10. Focus 2. 
   rewrite AddUnion. unfoldTac. rewrite Union_associative. eauto. 
   unfoldTac. rewrite AddUnion in *. repeat rewrite Union_associative in *. 
   apply wfWithoutPure in H10. inv H10. constructor. rewrite unspecUnionComm. 
   simpl. rewrite spec_multi_unused. eauto. }
  {inv H0. econstructor; eauto. erewrite unspecHeapRBRead; eauto. 
   rewrite unspecUnionComm in *. eraseTrmTac s1' M. erewrite unspecEraseTrm; eauto. 
   erewrite unspecLastActPool in H3. Focus 2. constructor. eapply readFastForward in H3. 
   Focus 2. eapply unspecHeapLookupFull; eauto. Focus 2. eauto. Focus 2. intros c. 
   inv c. invertHyp. eapply spec_multi_trans. rewrite spec_multi_unused. 
   eassumption. copy H3. eapply monotonicReaders in H3; eauto. invertHyp.
   apply listTailEq in H9; auto. subst.  eapply readSimPureSteps in H7; eauto. Focus 2. 
   rewrite app_nil_l. simpl. eassumption. invertHyp. eapply spec_multi_trans.
   rewrite spec_multi_unused. eassumption. destructLast s1'. 
   {inv H2; try solve[invertListNeq]. rewrite spec_multi_unused. rewrite spec_multi_unused in H7. 
    eapply stepWithoutReader; eauto. }
   {invertHyp. eapply readSimActionSteps; eauto. constructor. simpl. rewrite <- app_assoc in H7. 
    simpl in *. auto. }
  }
  {inv H0. econstructor; eauto. erewrite unspecHeapCommitCreateFull; eauto.
   rewrite unspecUnionComm in *. eraseTrmTac s1' M. erewrite unspecEraseTrm; eauto. 
   erewrite unspecLastActPool in H3. Focus 2. constructor.
   eapply writeFastForward in H3; eauto. Focus 2. eapply lookupUnspecEmpty; eauto. 
   invertHyp. eapply spec_multi_trans. eapply spec_multi_unused. eassumption. 
   eapply writeSimPureSteps in H3; eauto. invertHyp. eapply spec_multi_trans. 
   rewrite spec_multi_unused. eassumption. destructLast s1'. 
   {simpl in *. inv H2; try solve[invertListNeq]. eapply helper; eauto. rewrite spec_multi_unused. 
    rewrite spec_multi_unused in H3. assumption. }
   {invertHyp. eapply writeSimActionSteps; eauto. eauto. constructor. simpl. rewrite <- app_assoc in H3. 
    simpl in *. assumption. }
  }                   
  {inv H0. econstructor; eauto. erewrite unspecHeapCommitNewFull; eauto. 
   rewrite unspecUnionComm in *. eraseTrmTac s1' M. erewrite unspecEraseTrm; eauto. 
   erewrite unspecLastActPool in H3. Focus 2. constructor. eapply newFastForward in H3; eauto. 
   Focus 2. eapply lookupCreatedSpecFull; eauto. invertHyp. eapply spec_multi_trans.
   rewrite spec_multi_unused. eassumption. eapply newSimPureStepsFull in H3; eauto. 
   inv H3.  
   {invertHyp. eapply spec_multi_trans. rewrite spec_multi_unused. eassumption. 
    destructLast s1'. 
    {inv H2; try invertListNeq. simpl in *. rewrite spec_multi_unused. 
     rewrite spec_multi_unused in H5. clear H4. eapply smultiReplaceEmptyFull; eauto. }
    {invertHyp. eapply newSimActionStepsEmptyFull; eauto.  constructor. 
     rewrite <- app_assoc in H5. simpl in *. assumption. }
   }
   {invertHyp. eapply spec_multi_trans. rewrite spec_multi_unused. eassumption. 
    destructLast s1'. 
    {inv H2; try invertListNeq. rewrite spec_multi_unused. rewrite spec_multi_unused in H3. 
     clear H4. eapply smultiReplaceSpecFull; eauto. }
    {invertHyp. eapply newSimActionStepsFullFull; eauto. constructor.  rewrite <- app_assoc in H3.
     simpl in *. eassumption. }
   }
  }
  {inv H0. econstructor; eauto. erewrite unspecHeapCommitNewEmpty; eauto. 
   rewrite unspecUnionComm in *. eraseTrmTac s1' M. erewrite unspecEraseTrm; eauto. 
   erewrite unspecLastActPool in H3. Focus 2. constructor. eapply newFastForward in H3; eauto. 
   Focus 2. eapply lookupCreatedSpecEmpty; eauto. invertHyp. eapply spec_multi_trans.
   rewrite spec_multi_unused. eassumption. eapply newSimPureStepsEmpty in H3; eauto. 
   invertHyp. eapply spec_multi_trans. rewrite spec_multi_unused. eassumption. 
   destructLast s1'. 
   {simpl in *. inv H2; try invertListNeq. rewrite spec_multi_unused.
    rewrite spec_multi_unused in H3. eapply smultiReplaceEmpty; eauto. }
   {invertHyp. eapply newSimActionStepsEmpty; eauto. constructor. rewrite <- app_assoc in H3. 
    simpl in *. assumption. }
  } 
  {inv H0. econstructor; eauto. unfoldTac. rewrite coupleUnion in *. 
   repeat rewrite unspecUnionComm in *. eraseTrmTac s1' M. rewrite unspecEmpty in H2. 
   unfoldTac. rewrite union_empty_r in H2. eraseTrmTac s1'' N. 
   repeat erewrite unspecEraseTrm; eauto. rewrite <- coupleUnion in H2. 
   erewrite unspecLastActPool in H2. Focus 2. constructor. 
   eapply forkFastForward in H2; eauto. invertHyp. eapply spec_multi_trans. 
   erewrite spec_multi_unused. eassumption. repeat rewrite <- coupleUnion. 
   eapply forkCatchup' in H2; eauto. invertHyp. destructLast s1'. 
   {destructLast s1''. 
    {inv H3;inv H0; try invertListNeq. rewrite spec_multi_unused. simpl in *.  
      unfoldTac. rewrite spec_multi_unused in H6. assumption. }
    {invertHyp. inv H0; try invertListNeq. unfoldTac. flipCouples. flipCouplesIn H6.  
      repeat rewrite coupleUnion in *. repeat rewrite Union_associative in *. 
      rewrite spec_multi_unused. rewrite spec_multi_unused in H6. apply eraseTrmApp in H3. 
      eapply forkSimActStepsLocked; eauto. constructor. constructor. }
   }
   {invertHyp. destructLast s1''. 
    {inv H3; try invertListNeq. unfoldTac. repeat rewrite coupleUnion in *. 
     repeat rewrite Union_associative in *. rewrite spec_multi_unused. 
     rewrite spec_multi_unused in H6. eapply forkSimActStepsUnlocked; eauto. 
     constructor. rewrite <- app_assoc in H6. simpl in *. auto. }
    {invertHyp. eapply forkSimActSteps; eauto. constructor. constructor. 
     rewrite <- app_assoc in H6. simpl in *. assumption. }
   }
  }
  {inv H0. econstructor; eauto. unfoldTac. rewrite coupleUnion in *.  
   repeat rewrite unspecUnionComm in *. eraseTrmTac s1' M'. eraseTrmTac s1'' M''. 
   repeat erewrite unspecEraseTrm; eauto. erewrite unspecLastActPool in H2. 
   Focus 2. constructor. rewrite unspecEmpty in H2. unfoldTac.
   rewrite union_empty_r in H2.  rewrite <- coupleUnion in H2. 
   eapply PopSpecFastForward in H2; eauto. invertHyp.
   eapply spec_multi_trans. erewrite spec_multi_unused. eassumption. 
   repeat rewrite <- coupleUnion. unfoldTac. flipCouplesIn H2. 
   repeat rewrite coupleUnion in H2. repeat rewrite Union_associative in H2. 
   eapply forkCatchupL in H2; eauto. Focus 2. simpl. auto. Focus 2. simpl. auto. 
   invertHyp. eapply ind in H6; eauto. invertHyp. unfoldTac. 
   rewrite <- Union_associative in H7. rewrite <- coupleUnion in H7. flipCouplesIn H7. 
   destructLast s1'. 
   {inv H0; try invertListNeq. rewrite couple_swap in H7.  rewrite coupleUnion in H7. 
    rewrite Union_associative in H7. rewrite spec_multi_unused in H7. flipCouples.  
    repeat rewrite coupleUnion. repeat rewrite Union_associative. rewrite UnionSwap. 
    rewrite spec_multi_unused. apply simSpecStackSteps. assumption. }
   {invertHyp. eapply specSimActSteps; eauto. constructor. rewrite <- app_assoc in H7.
    unfoldTac. rewrite (couple_swap thread (tid,unlocked(x6++[x5]++[srAct t0 E M N d]), s2,M')).  
    simpl. rewrite coupleUnion in *. rewrite coupleUnion. simpl in *. unfold Union in *. 
    rewrite <- app_assoc in H7. assumption. }
  }
  Grab Existential Variables. eapply lookupCreatedSpecEmpty; eauto. 
  eapply lookupCreatedSpecFull; eauto. 
Qed. 