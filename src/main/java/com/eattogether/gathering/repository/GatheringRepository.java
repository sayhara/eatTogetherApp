package com.eattogether.gathering.repository;

import com.eattogether.gathering.domain.FoodCategory;
import com.eattogether.gathering.domain.Gathering;
import com.eattogether.gathering.domain.GatheringStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface GatheringRepository extends JpaRepository<Gathering, Long> {

    @Query("""
        SELECT DISTINCT g FROM Gathering g
        JOIN FETCH g.host
        LEFT JOIN FETCH g.participants
        WHERE g.status = :status
          AND g.mealTime > :now
          AND g.latitude  BETWEEN :minLat AND :maxLat
          AND g.longitude BETWEEN :minLng AND :maxLng
          AND (:category IS NULL OR g.category = :category)
          AND (:keyword IS NULL
               OR LOWER(g.title) LIKE :keyword
               OR LOWER(g.restaurantName) LIKE :keyword)
        ORDER BY g.mealTime ASC
        """)
    List<Gathering> findByBoundingBox(
            @Param("status") GatheringStatus status,
            @Param("now") LocalDateTime now,
            @Param("minLat") Double minLat, @Param("maxLat") Double maxLat,
            @Param("minLng") Double minLng, @Param("maxLng") Double maxLng,
            @Param("category") FoodCategory category,
            @Param("keyword") String keyword);

    @Query("SELECT g FROM Gathering g JOIN FETCH g.host WHERE g.host.id = :hostId ORDER BY g.createdAt DESC")
    List<Gathering> findByHostId(@Param("hostId") Long hostId);

    @Query("""
        SELECT g FROM Gathering g
        JOIN FETCH g.host
        JOIN g.participants p
        WHERE p.user.id = :userId
        ORDER BY g.mealTime ASC
        """)
    List<Gathering> findJoinedByUserId(@Param("userId") Long userId);
}
