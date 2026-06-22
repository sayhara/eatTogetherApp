package com.eattogether.location;

import com.eattogether.common.response.ApiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClient;

import java.util.List;

@RestController
@RequestMapping("/api/location")
public class LocationController {

    @Value("${spring.security.oauth2.client.registration.kakao.client-id}")
    private String kakaoClientId;

    private final RestClient restClient = RestClient.create();

    @GetMapping("/search")
    public ApiResponse<List<LocationResult>> search(@RequestParam String keyword) {
        KakaoLocalResponse response = restClient.get()
                .uri("https://dapi.kakao.com/v2/local/search/keyword.json?query={q}&size=15", keyword)
                .header("Authorization", "KakaoAK " + kakaoClientId)
                .retrieve()
                .body(KakaoLocalResponse.class);

        if (response == null || response.documents() == null) {
            return ApiResponse.ok(List.of());
        }

        List<LocationResult> results = response.documents().stream()
                .map(doc -> new LocationResult(
                        doc.place_name(),
                        doc.road_address_name() != null && !doc.road_address_name().isBlank()
                                ? doc.road_address_name() : doc.address_name(),
                        doc.y() != null ? Double.parseDouble(doc.y()) : null,
                        doc.x() != null ? Double.parseDouble(doc.x()) : null
                ))
                .toList();

        return ApiResponse.ok(results);
    }

    record LocationResult(String name, String address, Double latitude, Double longitude) {}

    record KakaoDocument(
            String place_name,
            String address_name,
            String road_address_name,
            String x,
            String y
    ) {}

    record KakaoLocalResponse(List<KakaoDocument> documents) {}
}
