package com.eattogether.review.repository;

import com.eattogether.review.domain.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    boolean existsByGatheringIdAndReviewerIdAndRevieweeId(Long gatheringId, Long reviewerId, Long revieweeId);

    @Query("SELECT r FROM Review r JOIN FETCH r.reviewer WHERE r.reviewee.id = :userId ORDER BY r.createdAt DESC")
    List<Review> findByRevieweeId(@Param("userId") Long userId);

    @Query("SELECT COALESCE(AVG(r.rating), 0.0) FROM Review r WHERE r.reviewee.id = :userId")
    Double findAverageRatingByRevieweeId(@Param("userId") Long userId);
}
