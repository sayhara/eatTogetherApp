package com.eattogether.report.repository;

import com.eattogether.report.domain.Report;
import com.eattogether.report.domain.ReportType;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportRepository extends JpaRepository<Report, Long> {

    boolean existsByReporterIdAndTypeAndTargetId(Long reporterId, ReportType type, Long targetId);
}
