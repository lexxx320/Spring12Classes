Require Import erasure.
Require Import Coq.Sets.Ensembles. 
Require Import errorIFF. 
Require Import SpecImpliesNonSpec.
Require Import SpecDivergeParDiverge. 

Inductive specFinalState : Type :=
|Done : trm -> specFinalState
|Diverge : specFinalState 
|Error : specFinalState. 

Inductive waitingOnEmpty : trm -> sHeap -> Prop := 
|waitingOnEmpty_ : forall t E x H, 
         decompose t E (get (fvar x)) -> heap_lookup x H = Some(sempty COMMIT) ->
         waitingOnEmpty t H.

Fixpoint specFinished H (T:pool) :=
  match T with
      |(_, unlocked nil, _, ret M)::Ts => specFinished H Ts
      |(_, unlocked nil, _, M)::Ts => waitingOnEmpty M H /\ specFinished H Ts
      |nil => True
      | _ => False
  end. 

Inductive specRunPar (M:trm) : specFinalState -> Prop :=
|specRunParDone : forall H' T tid s2 N, 
    multistep (Heap.empty ivar_state) 
              (tSingleton ([1], unlocked nil, nil, bind M (lambda (done (bvar 0)))))
              (Some(H', (tUnion T (tSingleton(tid, unlocked nil, s2, done N))))) -> 
    specFinished H' T -> specRunPar M (Done N)
|specRunParError :
   multistep (Heap.empty ivar_state) 
             (tSingleton ([1], unlocked nil, nil, bind M (lambda (done (bvar 0)))))
             None -> specRunPar M Error
|specrunParDiverge : 
   SpecDiverge (Heap.empty ivar_state) 
               (tSingleton([1],unlocked nil,nil,bind M (lambda (done (bvar 0))))) ->
   specRunPar M Diverge. 

Inductive parFinalState : Type :=
|pDone : ptrm -> parFinalState
|pDiverge : parFinalState 
|pError : parFinalState. 

Inductive pWaitingOnEmpty : ptrm -> pHeap -> Prop :=
|pwaitingOnEmpty_ : forall t E x H,
                      pdecompose t E (pget (pfvar x)) -> heap_lookup x H = Some pempty ->
                      pWaitingOnEmpty t H. 

Fixpoint parFinished H (T:pPool) :=
  match T with
    |pret M::Ts => parFinished H Ts
    |t::Ts => pWaitingOnEmpty t H /\ parFinished H Ts
    |nil => True
  end. 

Inductive parRunPar (M:ptrm) : parFinalState -> Prop :=
|parRunParDone : forall H' T N,
                   pmultistep (Heap.empty pivar_state) (pSingle (pbind M (plambda (pdone (pbvar 0)))))
                             (Some(H', pUnion T (pSingle (pdone N)))) -> parFinished H' T -> 
                   parRunPar M (pDone N)
|parRunParError : pmultistep (Heap.empty pivar_state) (pSingle (pbind M (plambda (pdone (pbvar 0)))))
                             None -> parRunPar M pError
|parRunParDiverge : ParDiverge (Heap.empty pivar_state) 
                               (pSingle(pbind M (plambda (pdone (pbvar 0))))) ->
                    parRunPar M pDiverge. 
                               

Inductive specBehavior (M:trm) : (Ensemble specFinalState) := 
|specBehavior_ : forall s, 
                   specRunPar M s -> Ensembles.In specFinalState (specBehavior M) s. 

Inductive parBehavior (M:ptrm) : (Ensemble parFinalState) :=
|parBehavior_ : forall s, parRunPar M s -> Ensembles.In parFinalState (parBehavior M) s. 

Inductive eraseBehaviors (b : Ensemble specFinalState) : Ensemble parFinalState :=
|eraseError : Ensembles.In specFinalState b Error -> 
              Ensembles.In parFinalState (eraseBehaviors b) pError
|eraseDone : forall M, Ensembles.In specFinalState b (Done M) ->
                       Ensembles.In parFinalState (eraseBehaviors b) (pDone (eraseTerm M))
|eraseDiverge : Ensembles.In specFinalState b Diverge -> 
                Ensembles.In parFinalState (eraseBehaviors b) pDiverge.

Theorem raw_eraseCommitEmpty : forall x H,
                             raw_heap_lookup x H = Some(sempty COMMIT) ->
                             raw_heap_lookup x (raw_eraseHeap H) = Some pempty. 
Proof.
  induction H; intros. 
  {inv H. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. 
   {inv H0. simpl. rewrite eq. auto. }
   {destruct i0. destruct s. eauto. simpl. rewrite eq; eauto. 
    destruct s. eauto. destruct s0; simpl; rewrite eq; eauto. }
  }
Qed. 

Theorem eraseCommitEmpty : forall x H,
                             heap_lookup x H = Some(sempty COMMIT) ->
                             heap_lookup x (eraseHeap H) = Some pempty. 
Proof.
  intros. destruct H. simpl. eapply raw_eraseCommitEmpty. eauto. 
Qed. 

Theorem waitingOnEmptyEq : forall e H,
                             waitingOnEmpty e H->
                             pWaitingOnEmpty (eraseTerm e) (eraseHeap H). 
Proof.
  intros. inv H0. erewrite <- decomposeErase in H2; eauto. econstructor. 
  simpl in *. eassumption. eapply eraseCommitEmpty; eauto. 
Qed. 

Theorem specFinishedParFinished : forall H T,
                                    specFinished H T -> 
                                    parFinished (eraseHeap H) (erasePool T). 
Proof.
  induction T; intros. 
  {auto. }
  {destruct a. destruct p. destruct p. destruct a. 
   {simpl in *. contradiction. }
   {destruct l0. simpl in H0. destruct t; try solve[invertHyp; 
    eapply waitingOnEmptyEq in H1; simpl in *; split; auto].
    simpl. eauto. simpl in *. contradiction. }
   {simpl in *. contradiction. }
  }
Qed. 

Ltac proveWF := econstructor; simpl; erewrite rawHeapsEq; auto; constructor. 

Theorem SpecEqPar : forall M, 
                      eraseBehaviors (specBehavior M) = parBehavior (eraseTerm M).
Proof.
  intros. eqSets. 
  {inv H. 
   {inv H0. constructor. inv H. constructor. eapply specErrorParErrorStar in H0. 
    simpl in *. unfold Heap.empty. erewrite rawHeapsEq. eauto. auto. proveWF. }
   {inv H0. inv H. copy H1. eapply specImpliesNonSpecMulti in H1. invertHyp. 
    constructor. rewrite eraseUnionComm in H0. simpl in H0. econstructor. 
    unfold Heap.empty. erewrite rawHeapsEq. eassumption. auto. 
    apply specFinishedParFinished; auto. proveWF. }
   {inv H0. inv H. constructor. eapply SpecDivergeParDiverge in H0. constructor. 
    unfold Heap.empty. erewrite rawHeapsEq. simpl in *. eassumption. auto. proveWF. }
  }
  {(*TODO: Par implies speculative*) admit. }
Qed. 

(*Assumed based on previous work*)
Axiom ParDet : forall M M' M'', parRunPar M M' -> parRunPar M M'' -> M' = M''. 

Ltac SpecDetTac := 
  match goal with
      |H:_ |- _ => eapply specImpliesNonSpecMulti in H
      |H:_ |- _ => eapply specErrorParErrorStar in H
      |H:_ |- _ => apply SpecDivergeParDiverge in H
  end. 

Ltac runParDoneTac M N :=
  try(rewrite eraseUnionComm in *); 
  assert(parRunPar (eraseTerm M) (pDone (eraseTerm N))) by 
    (econstructor;[simpl in *; unfold Heap.empty; erewrite rawHeapsEq; eauto|
                   eapply specFinishedParFinished; eauto]).

Ltac runParErrorTac M :=
  assert(parRunPar (eraseTerm M) pError) by
    (constructor; simpl in *; unfold Heap.empty; erewrite rawHeapsEq; eauto). 

Ltac runParDivergeTac M :=
  assert(parRunPar (eraseTerm M) pDiverge) by
    (constructor; simpl in *; unfold Heap.empty; erewrite rawHeapsEq; eauto). 

Ltac resultsDisagree := 
  match goal with
      |H:parRunPar ?M ?N,H':parRunPar ?M ?N' |- _ => eapply ParDet in H; eauto; solveByInv
  end. 

Theorem SpecDet : forall M M' M'', specRunPar M M' -> specRunPar M M'' -> M' = M''.
Proof.
  intros. inv H; inv H0; try (SpecDetTac;[SpecDetTac;[idtac|proveWF]|proveWF]); auto. 
  {invertHyp. runParDoneTac M N. runParDoneTac M N0. eapply ParDet in H; eauto. 
   inv H. apply eraseTermUnique in H6. subst. auto. }
  {invertHyp. runParDoneTac M N. runParErrorTac M. resultsDisagree. }
  {invertHyp. runParDoneTac M N. runParDivergeTac M. resultsDisagree. }
  {invertHyp. runParDoneTac M N. runParErrorTac M. resultsDisagree. }
  {runParErrorTac M. runParDivergeTac M. resultsDisagree. }
  {invertHyp. runParDoneTac M N. runParDivergeTac M. resultsDisagree. }
  {runParDivergeTac M. runParErrorTac M. resultsDisagree. }
Qed. 









